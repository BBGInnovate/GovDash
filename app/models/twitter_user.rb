class TwitterUser < ActiveRecord::Base
  serialize :access_token_obj
  
  
  TWITTER_ATTRIBUTES = [
    :name,
    :location,
    :description,
    :url,
    :protected,
    :profile_background_color,
    :profile_sidebar_fill_color,
    :profile_link_color,
    :profile_sidebar_border_color,
    :profile_text_color,
    :profile_background_image_url,
    :profile_background_tile,
    :friends_count,
    :statuses_count,
    :followers_count,      
    :favourites_count,
    :time_zone,
    :utc_offset,
    :first_name,
    :last_name
  ]

  def self.identify_or_create_from_access_token(token, secret=nil)
    raise ArgumentError, 'Must authenticate with an OAuth::AccessToken or the string access token and secret.' unless (token && secret) || token.is_a?(OAuth::AccessToken)
    
    token = OAuth::AccessToken.new(BasicOauth.consumer, token, secret) unless token.is_a?(OAuth::AccessToken)

    response = token.get("#{BasicOauth.base_url}/#{BasicOauth.api_version}/account/verify_credentials.json")
    user_info = handle_response(response)

    if user = self.find_by_identifier(user_info['screen_name'])
      # user.assign_twitter_attributes(user_info)
      user.access_token = token.token
      user.access_token_secret = token.secret
      user.access_token_obj = token
      user.save
      user
    else
      create_from_twitter_hash_and_token(user_info, token) 
    end
  end
  
  # access_token = TwitterUser.first.access_token_obj
  # response = access_token.request(:get, "https://api.twitter.com/1.1/statuses/home_timeline.json")
  #
  def self.create_from_twitter_hash_and_token(user_info, access_token)
    user = new_from_twitter_hash(user_info)
    user.access_token = access_token.token
    user.access_token_secret = access_token.secret
    user.access_token_obj = access_token
    user.save
    user
  end
  
  def self.handle_response(response)
    case response
      when Net::HTTPOK 
      begin
        JSON.parse(response.body)
      rescue JSON::ParserError
        response.body
      end
      when Net::HTTPUnauthorized
      raise Exception, 'The credentials provided did not authorize the user.'
    else
      message = begin
        JSON.parse(response.body)['error']
      rescue JSON::ParserError
        if match = response.body.match(/<error>(.*)<\/error>/)
          match[1]
        else
              'An error occurred processing your Twitter request.'
        end
      end
      
      raise Exception, message
    end
  end
  
  def self.new_from_twitter_hash(hash)
    raise ArgumentError, 'Invalid hash: must include screen_name.' unless hash.key?('screen_name')
    raise ArgumentError, 'Invalid hash: must include id.' unless hash.key?('id')

    user = self.new
    user.identifier = hash['screen_name']
    user
  end
  
  def assign_twitter_attributes(hash)
    TwitterUser.make_name(hash)
    TWITTER_ATTRIBUTES.each do |att|
      send("#{att}=", hash[att.to_s]) if respond_to?("#{att}=")
    end
  end

  def self.from_remember_token(token)
    first(:conditions => ["remember_token = ? AND remember_token_expires_at > ?", token, Time.now])
  end

  def update_twitter_attributes(hash)
    assign_twitter_attributes(hash)
    save
  end

  def utilize_default_validations
    false
  end
  
  def create_profile(twitter_id)
     p = Profile.new
     p.user_id= self.id
     p.avatar_url = "http://img.tweetimag.es/i/#{twitter_id}_n"
     p.profile_url_small = "http://img.tweetimag.es/i/#{twitter_id}_m"
     p.save(false)
  end
  
  def remember_me
    return false unless respond_to?(:remember_token)

    self.remember_token = ActiveSupport::SecureRandom.hex(10)
    self.remember_token_expires_at = Time.now + BasicOauth.remember_for.days
    save
    {:value => remember_token, :expires => remember_token_expires_at}
  end

  def forget_me
    self.remember_token = remember_token_expires_at = nil
    self.save
  end

  def self.make_name(hash)
    names = hash['name'].split
    hash['last_name'] = names.pop
    hash['first_name'] = names.join(' ')
  end
end
