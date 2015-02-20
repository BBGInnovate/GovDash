require Rails.root.to_s + '/lib/write_fb_page'

class FacebookAccount < Account
  include WriteFbPage
  attr_accessor :graph_api, :insights, :show_raw
  
  has_many :fb_pages, -> { order 'post_created_time desc' }, :foreign_key=>:account_id
  has_many :fb_posts, -> { order 'post_created_time desc' }, :foreign_key=>:account_id
  
  belongs_to :app_token, foreign_key: :contact, primary_key: :api_user_email,
    inverse_of: :facebook_accounts
  
  # below to be removed
  has_many :api_tokens, :foreign_key=>"account_id"
  
  after_initialize :do_this_after_initialize
  
   def do_this_after_initialize
     if self.new_item && self.new_item?
       @since_date = 3.months.ago
     end
   end

# main entry point to process facebook data
  QUERY_LIMIT = 250
  SCHEDULED_DELAY = 1.hour.from_now
  def self.archive
     started = Time.zone.now
     count = 0
     no_count = 0
     records = includes(:api_tokens).where("is_active=1").
       references(:api_tokens).to_a
     records.shuffle.each_with_index do |a,i|
       if !!a.graph
         if a.archive
           count += 1
           logger.info "Sleep #{SLEEP} seconds for next account"
           sleep SLEEP
         else
           # delayed_retrieve
           # logger.info "   retrieve scheduled deplayed_job in one hour"
         end
       else
         no_count += 1
         logger.info "    Account #{a.id} : No page_access_token "

       end
       
     end
     server = ActionMailer::Base.default_url_options[:server]
     ended = Time.zone.now
     size = records.size - no_count
     total_seconds=(ended-started).to_i
     duration=Time.at(total_seconds).utc.strftime("%H:%M:%S")
     msg = "#{server} : #{count} out of #{size} Facebook accounts fetched. Started: #{started.to_s(:db)} Duration: #{duration}"
     level = ((size-count)/2.0).round % size
     log_error msg,level
  end

  def archive
    @since_date = 3.months.ago
    since = @since_date
    hasta = until_date
    started=Time.now
    success = nil
    data = FbPost.select("post_created_time").
       where(:account_id=>self.id,:post_created_time=>since.beginning_of_day..until_date.end_of_day).to_a
    data = data.map{|d| d.post_created_time.beginning_of_day}
    
    while (hasta > @since_date)
      # since = hasta - 3.months.to_i
      since = hasta - 1.day
      data1 = nil
      data2 = nil
      if 1==1 || ((since + 3.months.to_i) < until_date)
        data1 = data.detect{|d| d == since.beginning_of_day}  
        data2 = data.detect{|d| d == hasta.beginning_of_day}
        # not to re retrieve
        if !!data1 && !!data2 
          success = true
          logger.info "   SKIP: ID #{self.id}: retrieve archieve #{since.to_s(:db)} - #{hasta.to_s(:db)}"  
        else
          logger.info "   ID #{self.id}: retrieve archieve #{since.to_s(:db)} - #{hasta.to_s(:db)}"
          sleep 1  
          success = do_retrieve(since, hasta)
        end
      else
        logger.info "   ID #{self.id}: retrieve #{since.to_s(:db)} - #{hasta.to_s(:db)}"
        success = do_retrieve(since, hasta)
        sleep 1
      end
      hasta -= 1
    end
    if success
      upload_insights
      parse_insights
      self.update_attributes :new_item=>false,:status=>true,:updated_at=>Time.zone.now
    else
      # delayed_retrieve
      # logger.info "   retrieve scheduled deplayed_job in one hour"   
    end
    ended=Time.now
    logger.info "   finished retrieve #{started} - #{ended}"
  end
  
  def self.retrieve 
     started = Time.zone.now
     count = 0
     no_count = 0
     records = includes(:api_tokens).where("is_active=1").
       references(:api_tokens).to_a
     records.each_with_index do |a,i|
       if !!a.graph_api
         if a.retrieve
           logger.debug "Sleep #{SLEEP} seconds for next account"
           sleep SLEEP
         else
           # delayed_retrieve
           # logger.info "   retrieve scheduled deplayed_job in one hour"
         end
       else
         no_count += 1
       end
       
     end
     server = ActionMailer::Base.default_url_options[:server]
     ended = Time.zone.now
     size = records.size - no_count
     total_seconds=(ended-started).to_i
     duration=Time.at(total_seconds).utc.strftime("%H:%M:%S")
     msg = "#{server} : #{count} out of #{size} Facebook accounts fetched. Started: #{started.to_s(:db)} Duration: #{duration}"
     # for cronjob log:     
     puts msg      
     level = ((size-count)/2.0).round % size
     log_error msg,level
     
  end
  #
  # finish 1 years data for voiceofamerica: 1.5hours
  # 
  def retrieve
    # TODO remove !!self.graph after run once
    if self.new_item? # !!self.graph
      @since_date = 6.months.ago
    end
    since = since_date
    hasta = until_date
    started=Time.now
    success = nil
    data = FbPost.select("post_created_time").
       where(:account_id=>self.id,:post_created_time=>since.beginning_of_day..until_date.end_of_day).to_a
    data = data.map{|d| d.post_created_time.beginning_of_day}
    while (hasta - since_date) >= back_to_date
      since = hasta - back_to_date
      data1 = nil
      data2 = nil
      if (since + back_to_date) < until_date
        data1 = data.detect{|d| d == since.beginning_of_day}  
        data2 = data.detect{|d| d == hasta.beginning_of_day}
        # not to re retrieve
        if !!data1 && !!data2 
          success = true
          logger.debug "   SKIP: retrieve archieve #{since.to_s(:db)} - #{hasta.to_s(:db)}"  
        else
          logger.debug "   retrieve archieve #{since.to_s(:db)} - #{hasta.to_s(:db)}"
          sleep 1  
          success = do_retrieve(since, hasta)
        end
      else
        logger.debug "   retrieve #{since.to_s(:db)} - #{hasta.to_s(:db)}"
        success = do_retrieve(since, hasta)
        sleep 1
      end
      hasta = since - 1
    end
    if success
      upload_insights
      parse_insights
      self.update_attributes :new_item=>false,:status=>true,:updated_at=>Time.zone.now
    else
      # delayed_retrieve
      # logger.info "   retrieve scheduled deplayed_job in one hour"   
    end
    ended=Time.now
    logger.info "   finished retrieve #{started} - #{ended}"
  end
  
    
  def do_retrieve(since=7.days.ago, hasta=Time.zone.now, rabbit=false)
    started = Time.zone.now
    logger.info "Facebook #{self.object_name} started: #{started.to_s(:db)}" 
    @num_attempts = 0
    begin
      @num_attempts += 1
      posts = graph_api.get_connections(self.obj_name, "posts", :fields=>"id,actions,comments,created_time",:limit=>QUERY_LIMIT, :since=>since, :until=>hasta) || []
      if posts.empty?
        logger.debug "  #{since.to_s(:db)}=#{hasta.to_s(:db)} do_retrieve posts empty   "
      end
    rescue Koala::Facebook::ClientError=>error
      if error.fb_error_type == 'OAuthException'
        log_fail "graph_api.get_connections() #{error.message}"
        self.update_attributes :status=>false,:updated_at=>Time.zone.now
        return false
      end
      if @num_attempts < self.max_attempts
        sleep RETRY_SLEEP
        retry
      else
        self.update_attributes :status=>false,:updated_at=>Time.zone.now
        log_fail "Tried #{@num_attempts} times. #{error.message}", 5
        
        delayed_do_retrieve(since, hasta)
        logger.info "   retrieve scheduled deplayed_job in one hour" 
      
        return false
      end
    rescue Exception=>error
      log_fail "graph_api.get_connections() #{error.message}"
      
      delayed_do_retrieve(since, hasta)
      logger.info "   retrieve scheduled deplayed_job in one hour" 
      
      self.update_attributes :status=>false,:updated_at=>Time.zone.now
      return false
    end
    
    begin     
      process_posts(posts)
      !!rabbit ? send_mq_message(rabbit) : save_post_details
    rescue Exception=>error
      logger.debug error.backtrace
      log_fail "process_posts() #{error.message}"
      self.update_attributes :status=>false,:updated_at=>Time.zone.now
      
      delayed_do_retrieve(since, hasta)
      logger.info "   retrieve scheduled deplayed_job in one hour" 
      
      return false
    end
    logger.info "   #{self.id} retrieve success"
    return 'Success'
  end
  
  def delayed_do_retrieve(since=7.days.ago, hasta=Time.zone.now, rabbit=false)
    retrieve since, hasta, rabbit
  end
  handle_asynchronously :delayed_do_retrieve,:run_at => Proc.new { SCHEDULED_DELAY }
  
  def process_posts(posts)
    return true if !posts || posts.empty?
    logger.debug "Process posts #{posts.size}"
    @bulk_insert = []
    last_created_time = Time.zone.now
    posts.each do |f|
      last_created_time= DateTime.parse(f['created_time'])
      if last_created_time > since_date
        replies_to_comment = get_replies_to_comment(f)          
        # no good way to tell a post is the original
        post_type = 'original'
        
        insert = {:account_id=>self.id,
                  :post_type=>post_type,
                  :replies_to_comment =>replies_to_comment,
                  :post_created_time=>last_created_time}
        dbpost = FbPost.find_or_create_by(:post_id=>f['id'])
        dbpost.update_attributes insert
        
      end
    end
    unless @bulk_insert.empty?
      FbPost.import!(@bulk_insert)
    end
    
    unless posts.size < QUERY_LIMIT 
      if last_created_time > since_date
        @num_attempts = 0
        begin
          @num_attempts += 1
          feeds = posts.next_page || []
        rescue Exception=>error
          if @num_attempts < self.max_attempts
            sleep RETRY_SLEEP
            retry
          else
            log_fail "Tried #{@num_attempts} times. #{error.message}", 5
            feeds = []
          end
        end
        begin
          process_posts(feeds)
        rescue Exception=>error
          log_fail "by process_posts #{error.message}", 2
        end
      end
    end
  end
  
  def save_post_details
     count = 0
     total_processed = 0
     started = Time.zone.now
     myposts = self.fb_posts.where("post_created_time > '#{since_date}'").to_a
     myposts.each do |post|
       count += 1
       total_processed += 1
       fin = Time.zone.now
       duration = fin.to_i - started.to_i
       if count > 10
           puts "Sleep #{SLEEP}"
           started - Time.zone.now
           count = 0
           sleep SLEEP
       end
       @num_attempts = 0
       data = {}
       begin
         @num_attempts += 1   
         insights = graph_api.graph_call("v2.1/#{post.post_id}/insights/post_story_adds_by_action_type")
         data=insights[0]['values'][0]['value'] rescue {}
       rescue Koala::Facebook::ClientError, Timeout::Error=>error
         if @num_attempts < self.max_attempts
           sleep RETRY_SLEEP
           retry
         else
           log_fail "Tried #{@num_attempts} times. #{error.message[0..200]}", 5
           logger.error error.message
         end
       rescue Exception=>error
         log_fail error.message
         logger.error error.message
       end
       completed = ((total_processed.to_f / myposts.size) * 100).to_i
       logger.debug "#{completed} % completed" if ((total_processed % 10)==0 )
       unless data.empty?
         like_count = data['like']
         comment_count = data['comment']
         share_count = data['share']
         post.update_attributes :likes=>like_count,
             :comments=>comment_count,
             :shares=>share_count
       else
         logger.debug "No Insights Data post_id #{post.post_id}"
       end
     end
     aggregate_data 1,'day', true
     # recent_page available after aggregate_data
     recent_page.save_lifetime_data
    
  end
  
  def upload_insights
    file_path = s3_filepath(Time.zone.now) + "insights.json"
    S3Model.new.store(file_path, get_insights.to_json)
  end
  
  def get_insights
    if !@insights
      duration = since_date
      @num_attempts = 0
      begin
        @num_attempts += 1
        @insights=graph_api.graph_call("v2.1/#{self.obj_name}/insights")
      rescue Timeout::Error=>error
        logger.error "Error: get_insights #{error.message}"
        if @num_attempts < self.max_attempts
          sleep RETRY_SLEEP
          retry
        else
          log_fail "Retried #{@num_attempts}"
        end
      rescue Exception=>error
        log_fail "#{error.message} -  Failed #{@num_attempts} times"
      end
    end
    @insights
  end
  
  # to get insights page_fan_adds_day metrix directly
  def get_insights_page_fan_adds_day
    duration = since_date
    @num_attempts = 0
    begin
     @num_attempts += 1
     @insight_fans=graph_api.graph_call("v2.1/#{self.obj_name}/insights/page_fan_adds/day?since=#{duration.to_i}")
    rescue Timeout::Error=>error
      logger.error "Error: upload_insights #{error.message}"
      if @num_attempts < self.max_attempts
        sleep RETRY_SLEEP
        retry
      else
        log_fail "Tried #{@num_attempts} times. #{error.message}", 5
      end
    rescue Exception=>error
      log_fail error.message
    end

    if !!@insight_fans && @insight_fans[0]
      values = @insight_fans[0]['values'] || []
    else
      values = []
      logger.debug "Account #{self.id}, no page_fan_adds/day "
    end
    values.each do |val|
      end_time = Time.zone.parse val['end_time']
      data = val['value']
      page = fb_pages.where("post_created_time BETWEEN '#{end_time.beginning_of_day}' AND '#{end_time.end_of_day}'").first
      if page && page.fan_adds_day != data
        page.update_attribute :fan_adds_day,data
      end
    end
    copy_lifetime_likes
  end
  
  def get_replies_to_comment(f)
    replies_to_comment = 0
    if f['comments'] && f['comments']['data']
      comment_id = f['comments']['data'][0]['id']
      @num_attempts = 0            
      begin
        @num_attempts += 1
        comments = graph_api.api("#{comment_id}/comments") 
        replies_to_comment = comments['data'].size
      rescue Koala::Facebook::ClientError=>error
        if @num_attempts < self.max_attempts
          sleep RETRY_SLEEP
          retry
        else
          log_fail "Tried #{@num_attempts} times. #{error.message}", 5
        end
      rescue Exception=>error
        log_fail error.message
      end
    end
    replies_to_comment
  end
  
  def self.fb_conf
    @fb_conf ||= YAML::load_file(File.join(Rails.root.to_s, 'config/facebook.yml'))[Rails.env]
  end
  
  def months_list
    @months_list ||= Facebook.config[:months_list].to_i
  end
  def weeks_list
    @weeks_list ||= Facebook.config[:weeks_list].to_i
  end
  def days_list
    @days_list ||= Facebook.config[:days_list].to_i
  end

  def since_date=(date)
    @since_date=date
  end
  
  def since_date
    if !@since_date
      since_str = Facebook.config[:since_date]
      since_str.match /(\d+\.\w+)\.ago/
      @back_to_date = (instance_eval $1).to_i
      
      if since_str.match /^(\d+\.(day|week|month)s*\.ago)/
        @since_date = instance_eval($1)
      else
        @since_date = 3.days.ago
      end
    end
    @since_date
  end
  def back_to_date
    if !@back_to_date
      since_str = Facebook.config[:since_date]
      since_str.match /(\d+\.\w+)\.ago/
      @back_to_date = (instance_eval $1).to_i
    end
    @back_to_date
  end
  def recent_posts
    @recent_posts ||= fb_posts.where("post_created_time > '#{since_date.to_s(:db)}'")
  end
  def max_post_date
    begin
      @max_post_date ||= recent_posts.first.post_created_time.end_of_day
    rescue
      @max_post_date = 1.year.ago
    end
  end
  def min_post_date
    begin
      @min_post_date ||= recent_posts.last.post_created_time.beginning_of_day
    rescue
      2.day.ago
    end
    
  end
  def recent_page
    @recent_page = fb_pages.order("post_created_time desc").first
  end
  
  def get_access_token
    # alternate select page_access_token
    begin
      idx = self.id % 2
      self.api_tokens[ idx ].page_access_token
    rescue Exception=>error
      logger.error  error.message
      nil
    end
  end
  
  def access_token_exists?
    arr = self.api_tokens.where("page_access_token is not null").to_a
    !arr.empty?
  end
  
  def graph
    if !@graph
      token = self.api_tokens.
        select('account_id,page_access_token').
        where("api_user_email='odditech@bbg.gov' AND page_access_token is not null").first
      if token
        @graph = Koala::Facebook::API.new(token.page_access_token)
      else
        return nil
      end
    end
    @graph
  end

  def graph_api(access_token=nil)
    access_token = access_token || page_access_token || user_access_token
    @graph_api = Koala::Facebook::API.new(access_token)
  end
  
  # insights fan_adds_day is 2 days behind
  # this to use lifetime likes diffrence to fill fan_adds_day
  def copy_lifetime_likes
    logger.debug "copy_lifetime_likes #{self.id} #{self.object_name}"
    (0..3).each do |i|
      if fb_pages[i] && !fb_pages[i].fan_adds_day
        if fb_pages[i].total_likes &&
           fb_pages[i+1].total_likes
          fb_pages[i].fan_adds_day = fb_pages[i].total_likes -
             fb_pages[i+1].total_likes
          fb_pages[i].save
        end
      end
    end  
  end
  
  # download insights from S3
  # return array of hashes
  def download_insights(date=Time.zone.now)
    path = s3_filepath(date) + "insights.json"
    logger.debug "Download from S3 #{path}. All dates are end date"
    results = []
    if since_date > 31.days.ago
      # since_date is within one month
      # get 1.month.ago insights.json file
      path1 = s3_filepath(date.months_ago(1)) + "insights.json"
      begin
        result2 = S3Model.new.json_obj path1
        results << result2
      rescue
        logger.error "ERROR #{$!} - #{path1}"
      end
      
      begin
        result1 = S3Model.new.json_obj path
        results << result1
      rescue
        logger.error "ERROR #{$!} - #{path}"
      end
    else
      begin
        result = S3Model.new.json_obj path
        results << result
      rescue
        logger.error "ERROR #{$!} - #{path}"
      end
    end

    arrays = []
    results.each do |result|
      arr = []
      result.each do |a|
        if a['id'].match /page_fan_adds_unique\/day$/
          # adds_unique_day(a)
        
        elsif a['id'].match /overall\/day$/
          arr << overall_day(a)
        elsif a['id'].match /overall\/week$/
          arr << overall_week(a)
        elsif a['id'].match /overall\/month$/
          arr << overall_month(a)
        elsif a['id'].match /overall\/lifetime$/
          arr << overall_lifetime(a)
        elsif a['id'].match /page_fan_adds\/day$/
          arr << page_fan_adds_day(a)
       
        elsif a['id'].match /page_story_adds\/day$/
        arr << page_story_adds_day(a)
        
        elsif a['id'].match /page_story_adds_by_story_type\/day$/
          arr << page_story_adds_by_story_type_day(a)
        
        elsif a['id'].match /page_consumptions\/day$/
          arr << page_consumptions_day(a)
        
        elsif a['id'].match /page_consumptions_by_consumption_type\/day$/
        # arr << page_consumptions_by_consumption_type_day(a)
        
        elsif a['id'].match /page_stories\/week/
          arr << page_stories_week(a)
        
        elsif a['id'].match /page_stories_by_story_type\/week/
          arr << page_stories_by_story_type_week(a)
        
        elsif a['id'].match /page_fans\/lifetime/
          page_fans a
        end
      end
      arrays << arr
    end
    show_raw ? results : merge_arrays(arrays)
  end
  
  def merge_arrays arrays
    if arrays.empty?
      ['No found']
    elsif arrays.size == 1
      arrays[0]
    else
      arrays[0].each do |a1|
        arrays[1].each do |a2|
          if a1['name'] == a2['name']
            if a2['values'].size == 1
               a2['values'][0] = a1['values'][0].merge(a2['values'][0]) rescue ''
            end       
          end
        end
      end
      arrays[1]
    end
  end
  
  def exchange_page_access_token(access_token=nil)
    token = access_token || user_access_token
    begin
      page_token = graph_api(token).graph_call("v2.0/#{self.send(:obj_name)}?fields=access_token&access_token=#{token}")
      if page_token['access_token']
        self.update_attribute :page_access_token, page_token['access_token']
      else
        logger.info "FacebookAccount: #{self.object_name} : no page_token['access_token']"
      end
    rescue Exception=>error
      logger.error error.message
    end
  end
  
  def token?
    !!app_token && !!app_token.page_access_token
  end
  
  def debug_token
     
    begin
      token = self.app_token.page_access_token
      if token
        end_point = "v2.1/debug_token?input_token=#{token}&access_token=#{token}"
        re = graph_api.graph_call end_point
        expiry = re['data']['expires_at']
        if expiry == 0
          'never'
        else
          expiry = (Time.at(expiry) - Time.zone.now) / 3600 
          "in about #{exp.to} hours"
        end
      else
        ''
      end
    rescue Exception=>ex
      'FB Error'
    end
    
  end

  def get_valid_date name
    name.match /_(week|day|month|lifetime)$/
    @period = $1
    valid_date = 4.days.ago.end_of_day
    if @period=='lifetime'
      increment = 1.day
      valid_date = max_post_date.months_ago(days_list)
    elsif @period=='month'
      increment = 1.month
      valid_date = max_post_date.months_ago(months_list)
    elsif @period=='week'
      increment = 1.week
      valid_date = max_post_date.weeks_ago(weeks_list)
    else
      increment = 1.day
      valid_date = max_post_date.days_ago(days_list)
    end
    [increment, valid_date]
  end
  
  def single_value content,name,desc
    increment,valid_date = get_valid_date name 
    hsh = {"name"=>name,"description"=>desc}
    hsh['values'] = []
    hsh2 = {}
    while valid_date.to_date < max_post_date
      content['values'].each do |co|
        end_time = (Time.parse co['end_time']).end_of_day
        if valid_date.to_date == end_time.to_date
          end_time = end_time.strftime("%Y-%m-%d")
          value = co['value'].to_i
          hsh2[end_time] = value
        end
      end
      valid_date = valid_date + increment
    end
    hsh['values'] = [hsh2]
    hsh
  end
  
  def nested_value content,name,desc
    increment,valid_date = get_valid_date name 
    root_hsh = {"name"=>name,"description"=>desc}
    arr = []
    end_time = nil
    while (valid_date.to_date < max_post_date)
      content['values'].each do |co|
        end_time = Time.parse co['end_time']
        if valid_date.to_date == end_time.to_date
          end_time = end_time.strftime("%Y-%m-%d")
          begin
            total = co['value'].values.inject { |a, b| a + b }
            value = co['value'].merge("total" => total)
            arr << {end_time => value }
          rescue
            puts "ERROR #{$!} #{co['value']}"
          end
          #
        end
      end
      valid_date = valid_date + increment
    end
    if @period == 'month'
      count = months_list
    elsif @period == 'week'
      count = weeks_list
    else
      count = days_list
    end
    root_hsh['values'] = arr.last(count)
    root_hsh
  end

  def adds_unique_day(content)
    raise "adds_unique_day not defined"
  end

  def self.get_insights_page_fan_adds_day
    self.all.each do |a|
      a.get_insights_page_fan_adds_day
    end
  end
  
  
  def send_mq_message rabbit
    payload = {:account_id => self.id, :date=>Time.zone.now.to_s(:db)}.to_yaml
    rabbit.channel.default_exchange.publish(payload,
            :type        => "save_post_details",
            :routing_key => "amqpgem.examples.patterns.command")
    rabbit.connection.close
  end
  
  
  protected
  def insights_life
    unless @insights_life
      @insights_life = {"id"=>"overall/lifetime","name"=>"overall_lifetime","period"=>"life time"}
      @insights_life["values"] = lifetime_data(1, 'day')
    end
    @insights_life
  end
  
  def insights_month
    unless @insights_month
      @insights_month = {"id"=>"overall/month","name"=>"overall_month","period"=>"month"}
      @insights_month["values"] =  aggregate_data 1,'month', false
    end
    @insights_month
  end
  def insights_week
    unless @insights_week
      @insights_week = {"id"=>"overall/week","name"=>"overall_week","period"=>"week"}
      @insights_week["values"] =  aggregate_data 1,'week', false
    end
    @insights_week
  end
  def insights_day
    unless @insights_day
      @insights_day = {"id"=>"overall/day","name"=>"overall_day","period"=>"day"}
      @insights_day["values"] =  aggregate_data 1,'day', true
    end
    @insights_day
  end
  
  def find_or_create_page(options)
    created_time = options.delete :post_created_time
    begin_date = created_time.beginning_of_day
    end_date = created_time.end_of_day
    
    re = FbPage.where("account_id=#{self.id} AND post_created_time BETWEEN '#{begin_date}' AND '#{end_date}' ").
      first
    if !re
      re = FbPage.create :account_id => self.id, :post_created_time=>created_time,
         :object_name => self.object_name
    end
    re.update_attributes options
  end
  
  
  def exist_posts
    @exist_posts ||= FbPost.all.map {|a| a.post_id}
  end
  
  def expire
  
  end
  
  def me  
    feeds=graph_api.graph_call("v2.1/me")
  end
  
  # period 1.day or 1.week or 1.month
  def lifetime_data number=1, unit="day"
    increment = instance_eval("#{number}.#{unit}")
    current_date = Time.zone.now.end_of_day
    my_arr = []
    while current_date > min_post_date do
      end_of_ = current_date.end_of_day
      if end_of_ > Time.zone.now.end_of_day
         break
      end
      logger.error "DATE #{current_date} > #{min_post_date}"
      data = select_lifetime_data end_of_
      if data
        my_arr << { "value"=>{"likes"=>data.total_likes,"comments"=>data.total_comments,
                            "shares"=>data.total_shares,"talking_about" => data.total_talking_about
                            },
                    "end_time"=>end_of_.to_s(:db)
                  }
      end
      current_date = current_date - 1.day
    end
    my_arr.reverse
  end
  
  def select_lifetime_data end_of
    data = fb_pages.where("post_created_time BETWEEN '#{end_of.beginning_of_day}' AND '#{end_of.end_of_day}'").
           first
  end
  
  # period 1.day or 1.week or 1.month
  def aggregate_data number=1, unit="month", create_page=false
    increment = instance_eval("#{number}.#{unit}")
    current_date = (Time.zone.now-0.day).end_of_day
    my_arr = []
    while current_date > min_post_date do
      beginning_of_ = (current_date-increment+1.day).beginning_of_day.to_s(:db)
      end_of_ = current_date.end_of_day
      if end_of_ > Time.zone.now.end_of_day
         break
      end
      # puts "DATE #{current_date} > #{min_post_date}"
      end_of_ = end_of_.to_s(:db)
      data = select_aggregated_data beginning_of_, end_of_
      
      options = {:likes=>data.likes, 
                 :comments=>data.comments,
                 :shares=>data.shares,
                 :posts => data.post_count,
                 :replies_to_comment => data.replies_to_comment
                }
      my_arr << { "value"=>options,
                  "start_date"=>beginning_of_,
                  "end_time"=>end_of_
                }
      if create_page
        options[:post_created_time] = current_date
        find_or_create_page(options)
      end
      # current_date = current_date - increment
      current_date = current_date - 1.day
    end
    my_arr.reverse
  end
  
  def select_aggregated_data beginning_of, end_of
    select_query = "post_type='original' AND (post_created_time BETWEEN '#{beginning_of}' AND '#{end_of}') "
    puts select_query
    data = recent_posts.select("count(*) AS post_count,sum(likes) as likes, sum(comments) as comments, sum(shares) as shares,sum(replies_to_comment) as replies_to_comment").
        where(select_query).
        first
  end
  
  def page_fan_adds_day(content)
    name = "page_fan_adds_day"
    desc = "Daily: The number of new people who have liked your Page (Total Count)"
    single_value(content,name,desc)
  end
  def overall_lifetime(content)
    name = "overall_lifetime"
    desc = "Lifetime: The numbers of likes, shares, comments, tolking_about"
    return nested_value(content,name,desc)
  end
  def overall_month(content)
    name = "overall_month"
    desc = "Monthly: The numbers of new likes, shares, comments, posts added for your posts"
    return nested_value(content,name,desc)
  end
  def overall_week(content)
    name = "overall_week"
    desc = "Weekly: The numbers of new likes, shares, comments, posts added for your posts"
    return nested_value(content,name,desc)
  end
  def overall_day(content)
    name = "overall_day"
    desc = "Daily: The numbers of new likes, shares, comments, posts added for your posts"
    return nested_value(content,name,desc)
  end
  
  def page_story_adds_day(content)
    name  ="page_story_adds_day"
    desc = "Daily: The number of stories created about your Page. (Total Count)"
    single_value(content,name,desc)
  end
  
  def page_story_adds_by_story_type_day(content)
    name  ="page_story_adds_by_story_type_day"
    desc = "Daily: The number of stories about your Page by story type. (Total Count)"
    nested_value(content,name,desc)
  end
  
  def page_consumptions_day(content)
    name  ="page_consumptions_day"
    desc = "Daily: The number of clicks on any of your content. (Total Count)"
    single_value(content,name,desc)
  end
  
  def page_consumptions_by_consumption_type_day(content)
    name  ="page_consumptions_by_consumption_type_day"
    desc = "Daily: The number of clicks on any of your content. (Total Count)"
    nested_value(content,name,desc)
  end
  
  def page_stories_week(content)
    name  ="page_stories_week"
    desc = "Weekly: The number of stories created about your Page. (Total Count)"
    single_value(content,name,desc) 
  end
  
  def page_stories_by_story_type_week(content)
    name  ="page_stories_by_story_type_week"
    desc = "Weekly: The number of stories about your Page by story type. (Total Count)"
    nested_value(content,name,desc)
  end
  
  def page_fans content
    # puts "AAAA #{content}.inspect"
  end
  
  public
  
  def get_likes_count(post_id)
    count = 0     
    feed = self.graph_api.get_object('/' + post_id + '/likes?limit=1000')
    while feed.size > 0
      count += feed.size
      feed = feed.next_page rescue []
    end  
    count
  end

  def self.populate
    # place holder
  end
  
end

  
