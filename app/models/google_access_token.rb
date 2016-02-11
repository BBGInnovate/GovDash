require "open-uri"

require 'google/api_client'
require 'google/api_client/client_secrets'
require 'google/api_client/auth/file_storage'
require 'google/api_client/auth/installed_app'

# require 'trollop'

class GoogleAccessToken < ActiveRecord::Base
  class << self
    def refresh_token!
      all.each do | tok |
        tok.refresh_token!
      end
    end
    
    def content_owner
      @content_owner ||= YoutubeConf[:content_owner]
    end
  end
  def refresh_token! force=false
    if token_expired? || force
      response = RestClient.post GoogleClient.token_credential_uri, 
                 :grant_type => 'refresh_token',
                 :refresh_token => self.refresh_token, 
                 :client_id => GoogleClient.client_id, 
                 :client_secret => GoogleClient.client_secret
      refreshhash = JSON.parse(response.body)
      token_will_change!
      expires_at_will_change!
      self.token     = refreshhash['access_token']
      self.expires_at = DateTime.now + refreshhash["expires_in"].to_i.seconds
      self.save
      puts 'Saved'
    else
      sec = (self.expires_at - Time.zone.now).to_i
      puts "  Token will expire in #{sec} seconds"
    end
  end
  # use google-api-client gem
  def client
    self.refresh_token!
    @client = Google::APIClient.new(
      :application_name => "Oddi",
      :application_version => '1.0.0'
    )
    @client.authorization = Signet::OAuth2::Client.new(
      token_credential_uri: 'https://www.googleapis.com/oauth2/v3/token',
      client_id: GoogleClient.client_id,
      client_secret: GoogleClient.client_secret,
      refresh_token: self.refresh_token,
      grant_type: 'refresh_token'
      )
    @client.authorization.fetch_access_token!
    @client
  end
  #
  # youtube.methods
  def youtube
    client.discovered_api('youtube', 'v3')
  end
  
  # 
  # exec_request(channel_request)
  # works
  def exec_request requestHash
    JSON.parse(client.execute!(requestHash).body)
  end
  # works
  def channel_request
  # The id parameter specifies a comma-separated list of the 
  # YouTube channel ID(s) for the resource(s) that are being retrieved
    {
      api_method: youtube.channels.list,
      parameters: {
        id: '',
        part: 'snippet'
      }
    }    
  end
  
  def playlist_request
    {
      api_method: youtube.playlist_items.list,
      parameters: {
        playlistId: "",
        part: 'snippet',
      }
    }    
  end
  
  protected

  def token_expired?
    expiry = self.expires_at
    (expiry < Time.now)
  end
  
  def test
    client = Google::APIClient.new
    client.authorization.client_id = GoogleClient.client_id
    client.authorization.client_secret = GoogleClient.client_secret
    client.authorization.access_token = self.token
    
    f = File.open "methods.txt",'w'
    client.discovered_apis.each do |gapi| 
    #  f.puts "#{gapi.title} \t #{gapi.id} \t #{gapi.preferred}"
    end; nil
    f.close
    
    api = client.discovered_api("admin", "directory_v1")
    puts "--- Users List ---"
    puts api.users.list.parameters

    plus = client.discovered_api('plus')
    data = client.execute( plus.people.list, :collection => 'connected', :userId => 'me').data
    p data
    
    api = client.discovered_api("youtubeAnalytics", "v1")
    # p api
    puts "--- youtubeAnalytics:v1 ---"
    p api.method_base
    p api.discovery_document
    # aaa = api.public_methods - Object.public_methods
    # aaa.sort.each {|a | p a} 
    
  end
end
