# https://dev.twitter.com/docs/auth/obtaining-access-tokens
# http://gettwitterid.com/?user_name=voa_news&submit=GET+USER+ID
# VOA_News twitter user id 16273831
    
class TwitterApp < Object # ActiveRecord::Base
  
  cattr_accessor :account

  class << self
    # extend ActiveSupport::Memoizable

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
=begin
    rest_client.user.tweets_count favorites_count
    rc = TwitterApp.rest_client
    
    rc.search("to:justinbieber marry me", :result_type => "recent").take(3).collect do |tweet|
      "#{tweet.user.screen_name}: #{tweet.text}"
      "#{tweet.user.profile_image_url}"
    end

    options = {result_type: "recent",max_id: '564787549688700928',
       count: 20}
    rc.search("#VOA", options).take(3).collect do |tweet|
      puts "#{tweet.user.screen_name}: #{tweet.text}"
      puts "  id #{tweet.id}"
      puts "  hashtags #{tweet.hashtags.map{|a| a.text}}"
    end

    rc.followers
    
    cursor = -1
    follower_ids = []
    begin
      response = rc.follower_ids(:cursor => cursor)
      follower_ids += response.follower_ids
      cursor = response.next_cursor
    end while cursor > 0


    user = rc.user 'VOA_News'
    content = user.to_json #=> show.json
    s3 = S3Model.new
    file_path = "twitter/#{Time.now.strftime("%d%b%y")}/user/#{user.screen_name}/show.json"
    s3.store(file_path, content)
    
    user.public_methods.sort.each{|a| puts a}
    
    timelines = rc.user_timeline :screen_name=>'voa_news',:count=>200  # max 200
    return Twitter::Tweet id in desc order
   
    timelines[0].retweet_count  #=> 4
    timelines.last.to_json
    
    timelines[0].public_methods.sort.each{|a| puts a}
    favorite_count retweet_count user_mentions
    
    timelines.each do |t|
      if t.user_mentions.size > 0
        puts "User mentions: #{t.user_mentions.size}"
      else
      
      end
    end
    
    rc.mentions_timeline
    rc.retweets 472153112359469056 # array of tweets
    user = rc.user 16273831
    
    user.screen_name #=> VOA_News
    user.tweets_count  #=> 34462    count for VOA_News
    user.statuses_count #=> same as tweets_count
    user.favorites_count
    user.followers_count #=> 105061
    user.friends_count #=> 156
    user.listed_count #=> 2760
    user.object_id #=> 2208474020
    x = rc.status 2208474020
    x.retweet_count
    
    retweet_count = 0
    timelines.each do |t|
      retweet_count += rc.retweets(timelines[0].id).size
    end
    puts "RETWEET COUNT #{retweet_count}"

    # Stream live Twitter data
    # The client must read messages faster than
    # the current rate of Tweets being added to the queue
    sc = TwitterApp.stream_client
    sc.public_methods.sort.each{|a| puts a}
    
    # Stream a random sample of all tweets
    sc.sample do |object|
      puts object.text if object.is_a?(Twitter::Tweet)
    end
    #
    # Stream mentions of coffee or tea
    topics = ["coffee", "tea"]
    sc.filter(track: topics.join(",")) do |object|
      puts object.text if object.is_a?(Twitter::Tweet)
    end
    
    # track hashtags
    sc = TwitterApp.stream_client
    topics = ["#help"]
    sc.filter(track: topics.join(",")) do |object|
      if object.is_a?(Twitter::Tweet)
        puts "  tweet_id: #{object.id}"
        puts "  language: #{object.lang}"
        puts "  screen_name: #{object.user.screen_name}"
        puts "  favorite_count: #{object.favorite_count}"
        puts "  retweet_count: #{object.retweet_count}"
        puts "  country: #{object.place}"
        puts "  text: #{object.text}"
      end  
    end
    
    
    # Stream tweets, events, and direct messages for the authenticated user
    # An object may be one of the following:
    # Twitter::Tweet
    # Twitter::DirectMessage
    # Twitter::Streaming::DeletedTweet
    # Twitter::Streaming::Event
    # Twitter::Streaming::FriendList
    # Twitter::Streaming::StallWarning   
    sc.user do |object|
      case object
      when Twitter::Tweet
        puts "It's a tweet!"
      when Twitter::DirectMessage
        puts "It's a direct message!"
      when Twitter::Streaming::StallWarning
        warn "Falling behind!"
      end
    end
    # 
    # Returns all public statuses
    # @note This endpoint requires special permission to access.
    sc.firehose do |object|
      case object
      when Twitter::Tweet
        puts "It's a tweet!"
      when Twitter::DirectMessage
        puts "It's a direct message!"
      when Twitter::Streaming::StallWarning
        warn "Falling behind!"
      end
    end
    #
    # Streams messages for a set of user
    # @note This endpoint requires special permission to access.
    sc.site("OddiDev") do |object|
      case object
      when Twitter::Tweet
        puts "It's a tweet!"
      when Twitter::DirectMessage
        puts "It's a direct message!"
      when Twitter::Streaming::StallWarning
        warn "Falling behind!"
      end
    end
    
    # A comma-separated list of longitude,latitude pairs specifying
    # a set of bounding boxes to filter Tweets by.
    # stream tweets from San Francisco
    sc.filter(locations: "-122.75,36.8,-121.75,37.8") do |tweet|
      puts tweet.text
    end
    #
    # A comma-separated list of phrases which will be used to 
    # determine what Tweets will be delivered on the stream
    sc.filter(track: "twitter", language: "en") do |tweet|
      puts tweet.text
    end
    
    sc.filter(follow: "OddiDev", language: "en") do |tweet|
      puts tweet.text
    end
    
=end
