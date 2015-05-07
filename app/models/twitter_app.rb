class TwitterApp < Object # ActiveRecord::Base
  
  cattr_accessor :account

  class << self
    def not_empty? text
      !!text && !text.strip.empty?
    end
    
    def config
      @config = 
        cnf = YAML.load_file("#{Rails.root}/config/twitter.yml")[Rails.env].symbolize_keys
    end

    def rest_client
      @client = Twitter::REST::Client.new do |c|
        c.consumer_key        = config[:consumer_key]
        c.consumer_secret     = config[:consumer_secret]
        c.access_token        = config[:access_token]
        c.access_token_secret = config[:access_token_secret]
      end
      @client.connection_options.merge(
         request: { open_timeout: 30, timeout: 60 } )
      @client
    end
    
    def stream_client
      @client = Twitter::Streaming::Client.new do |c|
        c.consumer_key        = config[:consumer_key]
        c.consumer_secret     = config[:consumer_secret]
        c.access_token        = config[:access_token]
        c.access_token_secret = config[:access_token_secret]
      end
    end
    
    # this client is used for retrieval 6 months data
    def special_client
      @special_client ||= Twitter::REST::Client.new do |c|
        c.consumer_key        = configure[:consumer_key]
        c.consumer_secret     = configure[:consumer_secret]
        c.access_token        = configure[:access_token]
        c.access_token_secret = configure[:access_token_secret]
      end
    end
    def configure
      @configure = 
        cnf = YAML.load_file("#{Rails.root}/config/twitter.yml")['staging'].symbolize_keys
    end
  end
end

 