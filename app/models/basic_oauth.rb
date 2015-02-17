class BasicOauth
  class Error < StandardError; end

  def self.config(conf='twitter')
    @config = 
       YAML.load_file("#{Rails.root}/config/#{conf}.yml")[Rails.env].symbolize_keys
  end

  def self.base_url
    config[:base_url]
  end

  def self.api_version
    config[:api_version]
  end
  
  def self.path_prefix
    URI.parse(base_url).path
  end

  def self.remember_for
    (config['remember_for'] || 14).to_i
  end

  # The OAuth consumer used for authentication. The consumer key and secret are set in your application's +config/twitter.yml+
  def self.consumer
    options = {:site => base_url}
    [ :authorize_path, 
      :request_token_path,
      :access_token_path,
      :scheme,
      :signature_method ].each do |oauth_option|
      options[oauth_option] = config[oauth_option.to_s] if config[oauth_option.to_s]
    end

    OAuth::Consumer.new(
      config[:consumer_key],          
      config[:consumer_secret],
      options 
    )
  end

end


