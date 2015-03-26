class TwitterAccount < Account
  attr_accessor :show_raw, :is_download
  has_many :tw_timelines,  -> { order 'tweet_created_at desc' }, :foreign_key=>:account_id
  has_many :tw_tweets,  -> { order 'tweet_created_at desc' }, :foreign_key=>:account_id
  
  # Run it in rails console for testing 
  def self.retrieve sincedate=nil
     started = Time.now
     count = 0
     begin
       records = where(:is_active=>true).all
       range = "0..#{records.size-1}"
       if TwitterApp.config[:retrieve_range] &&
          TwitterApp.config[:retrieve_range].match(/(\d+\.\.\d+)/)
           range = $1
       end
       records[eval range].each_with_index do |a,i|
         Rails.logger.debug "Start Twitter #{a.id}"
         if sincedate
           a.since_date = sincedate
         end
         if a.retrieve
           count += 1
         end
         Rails.logger.debug "Sleep 15 seconds for next account"
         sleep 15
       end
     rescue Exception=>ex
       logger.error "  TwitterAccount#retrieve #{ex.message}"
     end
     ended = Time.now
     size = records.size
     total_seconds=(ended-started).to_i
     duration=Time.at(total_seconds).utc.strftime("%H:%M:%S")
     msg = "#{count} out of #{size} Twitter accounts fetched. Started: #{started.to_s(:db)} Duration: #{duration}"
     # for cronjob log:          
     puts msg     
     # level = ((size-count)/2.0).round % size
     # log_error msg,level
  end
  def retrieve(rabbit_channel=false)
    @bulk_insert = []
    self.is_download = false
    begin
      if self.new_item?
        @since_date = 6.months.ago
      end
      timelines = request_twitter
      upload_timeline timelines
      process_timelines( timelines )
      if rabbit_channel
        send_mq_message rabbit_channel
      else
        summarize
      end
      # upload_show
      logger.info "   #{self.id} since: #{since_date.to_s(:db)} retrieve success"
      self.update_attributes :new_item=>false,:status=>true,:updated_at=>DateTime.now.utc
      return 'Success'
    rescue Exception=>error
      log_fail error.message
      logger.error "   #{error.backtrace}"
      self.update_attributes :status=>false,:updated_at=>DateTime.now.utc
      return false
      # raise error.message
    end
  end
  def delayed_retrieve()
    retrieve
  end
  # handle_asynchronously :delayed_retrieve,:run_at => Proc.new { 1.hour.from_now }
  
  # timeline.json
  def request_twitter timelines=nil
    @num_attempts = 0
    retweets = []
    options = {:screen_name=>self.object_name,
               :count=>200,
               :include_rt=>1}
    errors = [Twitter::Error::TooManyRequests,
              Twitter::Error::GatewayTimeout,
              Twitter::Error::ClientError,
              Twitter::Error::RequestTimeout]
    begin
     @num_attempts += 1
     if timelines
       opt = options.merge(:max_id=>timelines.last.id+1)
       retweets = client.user_timeline opt
     else
       today = DateTime.now.utc
       begin_time = since_date.beginning_of_day
       end_time = today.end_of_day
       last_tweet = tw_tweets.select("tweet_id").
          where("tweet_created_at BETWEEN '#{begin_time.to_s(:db)}' AND '#{end_time.to_s(:db)}'").
          order("tweet_created_at ASC").first
          
       last_tweet_id = !!last_tweet ? last_tweet.tweet_id : nil
       if last_tweet_id
         opt = options.merge(:since_id=>(last_tweet_id + 1))
       else
         opt = options
       end
       # https://dev.twitter.com/rest/reference/get/statuses/user_timeline
       # user_timeline method can only return up to 
       # 3,200 of a user’s most recent Tweets.
       # i.e. The user_timeline itself contains up to 3,200 possible statuses.
       retweets = client.user_timeline opt
       
     end  
    rescue Twitter::Error::TooManyRequests => error
      logger.error error.message
      if @num_attempts < self.max_attempts
        # NOTE: Your process could go to sleep for up to 15 minutes but if you
        # retry any sooner, it will almost certainly fail with the same exception.
        logger.error "SLEEP #{error.rate_limit.reset_in} sec"
        sleep (error.rate_limit.reset_in+1 || RETRY_SLEEP)
        retry
      else
        log_fail "Tried #{@num_attempts} times. #{error.message}", 5
        raise RepeatedFailException.new("request_twitter")
      end
    rescue Exception => error
      log_fail error.message
      logger.error("in request_twitter #{error.message}")
      # raise Exception.new("in request_twitter #{error.message}")
    end
    retweets
  end

  def process_timelines(timelines)
    logger.debug "   process_timelines count #{timelines.size}"
    sleep 2
        
    return if timelines.empty? || timelines.size==1
    @bulk_tweets = []
    # TODO this is lifetime followers at present
    # total_followers_count = timelines[0].user.followers_count
    timelines.each do | t |
      options = {:account_id=>self.id,
                :tweet_id => t.id,
                :tweet_created_at=>t.created_at,
                :favorites => t.favorite_count, 
                :retweets => t.retweet_count,
                :mentions => t.user_mentions.size}
      find_or_create_tweet(options)
      if t.created_at  < since_date
         logger.debug "  process_timelines break  #{t.created_at}  < #{since_date}"
         break
      end
    end
    
    unless @bulk_tweets.empty?
      last_id = TwTweet.import!(@bulk_tweets)
      from_id = last_id - @bulk_tweets.size
      # sync to Redshif database
      RedshiftTwTweet.upload from_id
      @bulk_tweets = []
      reload_tw_tweets
    end
    last_tweet = timelines.last 
    if last_tweet.created_at > since_date
      begin
        more_timelines = self.request_twitter timelines
      rescue Exception=>error
        more_timelines = []
      end
      process_timelines(more_timelines)
    end
  end
  
  def summarize
    @bulk_timelines = []
    tweets = self.tw_tweets.where("tweet_created_at > '#{since_date.to_s(:db)}'")
    if tweets.empty?
      return
    end
    min_date = tweets.last.tweet_created_at.beginning_of_day
    max_date = tweets.first.tweet_created_at.end_of_day
    current_date = max_date
 
    while current_date > min_date do
      beginning_of_day = current_date.beginning_of_day.to_s(:db)
      end_of_day = current_date.end_of_day.to_s(:db)
 
      data = tweets.select("count(*) AS tweet_count, sum(favorites) as favorites, sum(retweets) as retweets, sum(mentions) as mentions").
        where("tweet_created_at BETWEEN '#{beginning_of_day}' AND '#{end_of_day}' ").
        first
      
      options = {:object_name=>self.object_name,
         :account_id=>self.id,
         :tweets=>data.tweet_count,
         :favorites=>data.favorites, :retweets=>data.retweets, :mentions=>data.mentions,
         :tweet_created_at=>current_date}
         
      find_or_create_timeline(options)
      current_date = current_date - 1.day
    end
    unless @bulk_timelines.empty?
      last_id = TwTimeline.import! @bulk_timelines
      from_id = last_id - @bulk_timelines.size
      # sync to Redshif database
      RedshiftTwTimeline.upload from_id
      @bulk_timelines = []
    end
    create_today_timeline
  end
  
  def request_timeline 
    request_twitter
  end
  
  def request_show 
    twitter_user
  end
  
  def recent_timelines
    @recent_timelines = tw_timelines.where("tweet_created_at > '#{since_date.to_s(:db)}'")
  end
      
  def recent_tweets
    @recent_tweets ||= tw_tweets.where("tweet_created_at > '#{since_date.to_s(:db)}'")
  end
  
  def max_tweet_date
    begin
      @max_tweet_date ||= recent_tweets.first.tweet_created_at.end_of_day
    rescue
      @max_tweet_date = 1.month.ago
    end
  end
  def min_tweet_date
    begin
      @min_tweet_date ||= recent_tweets.last.tweet_created_at.beginning_of_day
    rescue
      1.day.ago
    end
  end
  
  def reload_tw_tweets
    tw_tweets.reload
    @recent_tweets = tw_tweets.where("tweet_created_at > '#{since_date.to_s(:db)}'")
  end
  
  def upload_show
    hsh = {}
    hsh['lifetime'] = twitter_user
    S3Model.new.store(s3_filepath+"show.json", hsh.to_json) 
  end
  
  def upload_timeline timelines
    S3Model.new.store(s3_filepath+"timeline.json", timelines.to_json)
  end

  def s3_show(date=DateTime.now.utc)
    self.is_download = true
    arr = get_show(date)
  end
  
  # read one show.json
  def get_show(date_str=DateTime.now.utc)
    date_str = date_str.end_of_day
    started = date_str  #  .days_ago(days_list)
 
    results = []
    while started <= date_str
      path = s3_filepath(started) + "show.json"
      end_time = started.strftime('%Y-%m-%d')
      begin
        hsh = {}
        content = S3Model.new.json_obj path
        if show_raw
          results = content
        else
          results << parse_lifetime_from_table
          results << get_aggregated(1.month,'month')
          results << parse_show_period(content, 'week')
          results << parse_show_period(content, 'day')
        end
      rescue Exception=>e
        logger.error "GET #{path}- #{e.backtrace}"
        hsh = {"name"=>self.object_name, "end_time"=> end_time, 
          "values"=> []}
        results << hsh
      end
      started += 1.day
    end
    results
  end
  
  def parse_lifetime_from_table
    increment = 1.day
    current_date = DateTime.now.utc.end_of_day
    my_arr = []
    
    result = {"name"=>self.object_name+"/lifetime"}
    result['values'] = []
    
    while current_date > 7.days.ago do
      beginning_of_ = (current_date-increment+1.day).beginning_of_day.to_s(:db)
      end_of_ = current_date.end_of_day
      if end_of_ > DateTime.now.utc.end_of_day
         break
      end
      end_of_ = end_of_.to_s(:db)
      data = select_timeline_data beginning_of_, end_of_
      result['values'] << { "value"=>{"tweets"=>data.tweets,"favorites"=>data.favorites,
                            "followers"=>data.followers
                            },
                  "start_date"=>beginning_of_,
                  "end_time"=>end_of_
                }
      
      current_date = current_date - increment  # 1.day
    end
    result['values'].reverse!
    
    if self.is_download
      limits = days_list
      result['values'] = result['values'].last(limits)
    end
    result
  end
  
  def select_timeline_data beginning_of, end_of
    cond = "tweet_created_at BETWEEN '#{beginning_of}' AND '#{end_of}' "
    query = "sum(total_favorites) as favorites, sum(total_tweets) as tweets,sum(total_followers) as followers"
    data = tw_timelines.select( query ).
        where(cond).
        first
  end


  def get_shows(date_str=DateTime.now.utc)
    date_str = date_str.end_of_day
    started = date_str.days_ago(days_list)
    arr = []
    result = {"name"=>self.object_name+"/lifetime"}
    result['values'] = []
    while started <= date_str
      path = s3_filepath(started) + "show.json"
      end_time = started.strftime('%Y-%m-%d')
      begin
        hsh = {}
        content = S3Model.new.json_obj path
        if show_raw
          arr = content
        else
          
            values = content.slice("followers_count","friends_count","listed_count","statuses_count")
            hsh['value'] = values
            hsh['end_time'] = started.strftime('%Y-%m-%d')
            result['values'] << hsh
            result['values'].last(days_list) if self.is_download
        
        end
      rescue
        logger.error "GET #{path}- #{$!}"
        hsh = {"name"=>self.object_name, "end_time"=> end_time, 
          "values"=> []}
        arr << hsh
      end
      started += 1.day
    end
    show_raw ? arr : result
  end
  
  def parse_show_lifetime content
    hsh = {}
    cont = content['lifetime'] || content
    result = {"name"=>self.object_name+"/lifetime"}
    result['values'] = []
    values = cont['lifetime'].slice("followers_count","friends_count","listed_count","statuses_count")
    hsh['value'] = values
    hsh['end_time'] = started.strftime('%Y-%m-%d')
    result['values'] << hsh
    result['values'].last(days_list) if self.is_download
    result
  end
  def parse_show_period content, period
    begin
      result = content[period]
      result['values'] = result['values'].last(eval("#{period}s_list")) # if self.is_download
      result
    rescue
      puts "ERROR parse_show_period #{$!}"
      {}
    end
  end

  def s3_timeline(date=DateTime.now.utc)
    self.is_download = true
    arr = get_lifetime(date)
    arr
  end
  
  def get_aggregated increment,unit
    aggregate_data increment,unit
  end
  
  def get_lifetime(date_str=DateTime.now.utc)
    arr = []
    date_str = date_str.end_of_day
    started = date_str.days_ago(days_list)
    result = {"name"=>self.object_name+"/lifetime"}
    result['values'] = []
    while started <= date_str
      path = s3_filepath(started) +  "timeline.json"
      begin
        hsh = {}
        b = S3Model.new.json_obj path
        if show_raw
          arr << b
        else
          values = b[0]['user'].slice("followers_count","friends_count","listed_count","statuses_count")
          values.merge! "tweets_count"=>values.delete('statuses_count')
          hsh['value'] = values
          hsh['end_time'] = started.strftime('%Y-%m-%d')
          result['values'] << hsh
          result['values'].last(days_list) if self.is_download
        end
      rescue
        logger.error "GET #{path} - #{$!}"
      end
      started += 1.day
    end 
    result
  end
  
    # period 1.day or 1.week or 1.month
  def aggregate_data increment, unit
    # increment = instance_eval("#{number}.#{unit}")
    current_date = DateTime.now.utc.end_of_day
    my_arr = []
    
    result = {"name"=>self.object_name+"/#{unit}"}
    result['values'] = []
    
    while current_date > increment.ago do
      beginning_of_ = (current_date-increment+1.day).beginning_of_day.to_s(:db)
      end_of_ = current_date.end_of_day
      if end_of_ > DateTime.now.utc.end_of_day
         break
      end
      end_of_ = end_of_.to_s(:db)
      data = select_aggregated_data beginning_of_, end_of_
      result['values'] << { "value"=>{"tweets"=>data.tweet_count,"favorites"=>data.favorites,
                            "retweets"=>data.retweets,"mentions" => data.mentions
                            },
                  "start_date"=>beginning_of_,
                  "end_time"=>end_of_
                }
      
      current_date = current_date - increment  # 1.day
    end
    result['values'].reverse!
    
    if self.is_download
      limits = instance_eval("#{unit}s_list")
      result['values'] = result['values'].last(limits)
    end
    result
  end
  
  def select_aggregated_data beginning_of, end_of
    cond = "tweet_created_at BETWEEN '#{beginning_of}' AND '#{end_of}' "
    query = "count(*) AS tweet_count,sum(favorites) as favorites, sum(retweets) as retweets,sum(mentions) as mentions"
    data = recent_tweets.select( query ).
        where(cond).
        first
  end

  def get_valid_date name
    name.match /_(week|day|month|lifetime)$/
    @period = $1
    valid_date = 4.days.ago.end_of_day
    if @period=='lifetime'
      increment = 1.day
      valid_date = max_tweet_date.months_ago(days_list)
    elsif @period=='month'
      increment = 1.month
      valid_date = max_tweet_date.months_ago(months_list)
    elsif @period=='week'
      increment = 1.week
      valid_date = max_ptweet_date.weeks_ago(weeks_list)
    else
      increment = 1.day
      valid_date = max_tweet_date.days_ago(days_list)
    end
    [increment, valid_date]
  end
  
  def send_mq_message rabbit
    payload = {:account_id => self.id, :date=>DateTime.now.utc.to_s(:db)}.to_yaml
    rabbit.channel.default_exchange.publish(payload,
            :type        => "summarize",
            :routing_key => "amqpgem.#{self.class.name}")
    rabbit.connection.close
  end
  
  def find_account_country loc
    str = loc.split(',').last
    cn = Country.find_by name: str.strip
  end
  
  def update_profile options={}
    user = twitter_user
    options[:platform_type] = 'TW'
    options[:display_name] = user.name
    options[:description] = user.description
    options[:avatar] = user.profile_image_url.to_s
    options[:total_followers] = user.followers_count
    options[:location] = user.location
    options[:url] = user.url.to_s
    options[:verified] = user.verified?
    super
  end
  
  def create_today_timeline
    # create or update Today's timeline for lifetime data
    today = DateTime.now.utc
    started = (today-1.day).beginning_of_day.to_s(:db)
    ended = today.end_of_day.to_s(:db)
    cond = "tweet_created_at BETWEEN '#{started}' AND '#{ended}' AND account_id=#{self.id}"
           
    tl = TwTimeline.where(cond).order("tweet_created_at")
    if !tl.empty? && 
      (tl[0].tweet_created_at.to_date==today.to_date)
      return
    end
    begin
      user = twitter_user
      
      update_profile
      
      hsh = {}
      hsh['lifetime'] = user
      S3Model.new.store(s3_filepath+"show.json", hsh.to_json) 
    rescue Exception=>error
      logger.error "  #{error.message}"
      raise "create_today_timeline #{error.message}"
    end
    if tl[0] && tl[0].total_followers      
      net_followers_for_day = user.followers_count - tl[0].total_followers.to_i
    else
      net_followers_for_day = 0
    end
    options = {:object_name=>self.object_name,
               :account_id=>self.id,
               :total_tweets => user.tweets_count,
               :followers => net_followers_for_day,
               :total_favorites => user.favorites_count,
               :total_followers => user.followers_count}
           
    if tl[1] && tl[1].tweet_created_at.to_date==today.to_date
      tl[1].update_attributes options
    else
      options[:tweet_created_at] = DateTime.now.utc
      find_or_create_timeline(options)
    end
  end
  def find_or_create_timeline(options)
    created_time = options[:tweet_created_at]
    begin_date = created_time.beginning_of_day.to_s(:db)
    end_date = created_time.end_of_day.to_s(:db)
    timelines = TwTimeline.where(:tweet_created_at=> begin_date..end_date, :account_id=>self.id).to_a
    timeline = timelines.first    
    if timelines.size > 1
      # remove deplicates
      ids = timelines[1..-1].map{|t| t.id} 
      TwTimeline.delete_all(["id in (?)", ids])
      self.tw_timelines.reload
    end
    options[:tweet_created_at] = options[:tweet_created_at].to_s(:db)
    if !timeline
      timeline = self.tw_timelines.create options
      # @bulk_timelines << options
    else
      options[:updated_at] = DateTime.now.utc
      timeline.update_attributes options
    end
    timeline
  end
  
  
  def find_or_create_tweet(options)
    re = my_tweets.select{|t| t.tweet_id==options[:tweet_id]}.first
    if !re
      @bulk_tweets << options
    else
      re.update_attributes options
    end
  end
  
  def my_timelines
    @my_timelines = recent_timelines
  end
  
  def my_tweets
    @my_tweets = recent_tweets
  end
  
  def client
    if self.new_item?
      @client ||= TwitterApp.special_client
    else
      @client ||= TwitterApp.rest_client
    end
  end
    
  def debug_token
    'never for now'
  end
  
  # show.json = @twitter_user.to_json
  def twitter_user
    @num_attempts = 0
    errors = [Twitter::Error::TooManyRequests,
              Twitter::Error::GatewayTimeout,
              Twitter::Error::RequestTimeout]
    begin
      @num_attempts += 1
      @twitter_user ||= client.user self.object_name
    rescue *errors => error
      @twitter_user = nil
      if @num_attempts < self.max_attempts
        # NOTE: Your process could go to sleep for up to 15 minutes but if you
        # retry any sooner, it will almost certainly fail with the same exception.
        sleep_time = (error.rate_limit.reset_in+1 || RETRY_SLEEP)
        msg = "   Error get Twitter show.json #{error.message}. Retry in #{sleep_time} seconds"
        logger.error msg
        sleep sleep_time
        retry
      else
        log_fail "Tried #{@num_attempts} times. #{error.message}", 5
        raise
      end
    rescue Exception => error
      @twitter_user=nil
      msg = "Error get Twitter show.json #{error.message}"
      log_fail msg     
      logger.error msg
      raise
    end
    @twitter_user
  end
  
  
  def s3_filepath(date=DateTime.now.utc)
    if (date.class == String)
      date = Time.parse date_str
    end
    @s3_filepath = "twitter/#{date.strftime("%d%b%y")}/user/#{self.object_name}/"
  end
  
  def fetch_all_friends(twitter_username="VOA_News", max_attempts = 100)
    # in theory, one failed attempt will occur every 15 minutes, so this could be long-running
    # with a long list of friends
    @num_attempts = 0
    myfile = File.new("#{twitter_username}_friends_list.txt", "w")
    running_count = 0
    cursor = -1
    while (cursor != 0) do
    begin
      @num_attempts += 1
      # 200 is max, see https://dev.twitter.com/docs/api/1.1/get/friends/list
      friends = client.friends(twitter_username, {:cursor => cursor, :count => 200} )
      friends.each do |f|
        running_count += 1
        myfile.puts "\"#{running_count}\",\"#{f.name.gsub('"','\"')}\",\"#{f.screen_name}\",\"#{f.url}\",\"#{f.followers_count}\",\"#{f.location.gsub('"','\"').gsub(/[\n\r]/," ")}\",\"#{f.created_at}\",\"#{f.description.gsub('"','\"').gsub(/[\n\r]/," ")}\",\"#{f.lang}\",\"#{f.time_zone}\",\"#{f.verified}\",\"#{f.profile_image_url}\",\"#{f.website}\",\"#{f.statuses_count}\",\"#{f.profile_background_image_url}\",\"#{f.profile_banner_url}\""
      end
      puts "#{running_count} done"
      cursor = friends.send 'next_cursor'
      break if cursor == 0
    rescue Twitter::Error::TooManyRequests => error
      if @num_attempts <= self.max_attempts
        # NOTE: Your process could go to sleep for up to 15 minutes but if you
        # retry any sooner, it will almost certainly fail with the same exception.
        puts "#{running_count} done"
        logger.error "Hit rate limit, sleeping for #{error.rate_limit.reset_in}..."
        sleep error.rate_limit.reset_in+1
        retry
      else
        raise
      end
    end
  end
  end

  def self.populate
    # place holder
  end
  
  protected
  
end
