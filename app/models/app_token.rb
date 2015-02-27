class AppToken < ActiveRecord::Base

  self.table_name = "app_tokens"
#  has_many :twitter_accounts, :foreign_key=> :api_user_email
  has_many :facebook_accounts, foreign_key: :contact, primary_key: :api_user_email,
    inverse_of: :app_token
    
end
=begin 
  def graph_api(access_token=nil)
    access_token = access_token || page_access_token || user_access_token
    @graph_api = Koala::Facebook::API.new(access_token)
  end
  
  def exchange_page_access_token(access_token)
    if !access_token
      raise "  AppToken#exchange_page_access_token access_token is null"
    end
    self.facebook_accounts.each do |fb|
      obj = fb.send(:obj_name)
      fb.user_access_token = access_token
      token = access_token
      begin
        page_token = graph_api(access_token).graph_call("v2.2/#{obj}?fields=access_token&access_token=#{token}")
        if page_token['access_token']
          fb.page_access_token = page_token['access_token']
          fb.save!
        else
          logger.info "AppToken: #{self.canvas_url} : #{obj} : no page_token['access_token']"
        end
      rescue Exception=>error
        logger.error error.message
      end
    end
  end

  def token?
    !!page_access_token
  end
  
  def debug_token
    if token?
      'never'
    else
      'N/A'
    end
  end
=end

