# require Rails.root.to_s + '/lib/write_fb_page'
class FacebookAccount < Account
  # include WriteFbPage
  attr_accessor :graph_api
  
  has_many :fb_pages, -> { order 'post_created_time desc' }, 
      foreign_key: :account_id
  has_many :fb_posts, -> { order 'post_created_time desc' }, 
      foreign_key: :account_id

  has_many :fbpages, -> { order 'post_created_time' }, 
      foreign_key: :account_id
  
  after_initialize :do_this_after_initialize
  
   def do_this_after_initialize
     if self.new_item && self.new_item?
       @since_date = 3.months.ago
     else
       since_date
     end
     my_account_pages
     my_account_posts
   end

  # those account ids are retrieved with longer dates
  # say retrieve(6.months.ago)
  def self.more_history_data_ids
    if Facebook.config[:more_history_data_ids]
      Facebook.config[:more_history_data_ids].split(',').map(&:to_i)
    else
      []
    end
  end
  
  # 0 * * * * source /home/uberdash/.rvm/scripts/rvm && cd /home/uberdash/socialdash_app/current && bundle exec rails runner -e production  'FacebookAccount.start_job'  > /tmp/fb-start-job.log 2>&1
  def self.start_job
    pid = `pidof clockworkd.clock`.to_i
    if pid == 0
      `bundle exec clockworkd -c app/models/clock.rb start --log`
      puts "  clockwork job started"
    else
      puts "  clockwork job is running"
    end
  end

# main entry point to process facebook data
  QUERY_LIMIT = 100
  SCHEDULED_DELAY = 1.hour.from_now
  def self.archive
     started = Time.now
     count = 0
     no_count = 0
     records = includes(:api_tokens).where("is_active=1").
       references(:api_tokens).to_a
     records.shuffle.each_with_index do |a,i|
       if !!a.graph
         if a.archive
           count += 1
           logger.info "Sleep 5 seconds for next account"
           sleep 5
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
     ended = DateTime.now.utc
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
      self.update_attributes :new_item=>false,:status=>true,:updated_at=>DateTime.now.utc
    else
      # delayed_retrieve
      # logger.info "   retrieve scheduled deplayed_job in one hour"   
    end
    ended=Time.now
    logger.info "   finished retrieve #{started} - #{ended}"
  end
  
  def self.retrieve sincedate=nil, from_id=0, retrieve_range=nil
     started = Time.now.utc
     count = 0
     no_count = 0
     begin
       all_records = self.retrieve_records from_id
       special_accounts = self.where(["id in (?)",more_history_data_ids])
       records = all_records - special_accounts
       # special_accounts run for longer backwards date
       # bundle exec clockworkd -c app/models/clock.rb start --log
       range = "0..#{records.size-1}"
       if retrieve_range &&
          retrieve_range.match(/(\d+\.\.\d+)/)
         range = $1
       elsif Facebook.config[:retrieve_range] &&
             Facebook.config[:retrieve_range].match(/(\d+\.\.\d+)/)
         range = $1
       end
       records[eval range].each_with_index do |a,i|
         if sincedate
           a.since_date = sincedate
         end
         # if !!a.graph_api
           if a.retrieve
             count += 1
             Rails.logger.info "Finished #{a.id} Sleep 5 seconds for next account"
             sleep 5
           else
             # delayed_retrieve
             # logger.info "   retrieve scheduled deplayed_job in one hour"
           end
         # else
         #  no_count += 1
         # end
       end
     rescue Exception => ex
       logger.error "   retrieve #{ex.message}"  
     end
     # server = ActionMailer::Base.default_url_options[:server]
     ended = Time.now.utc
     size = records.size - no_count
     total_seconds=(ended-started).to_i
     duration=Time.at(total_seconds).utc.strftime("%H:%M:%S")
     msg = "#{count} out of #{size} Facebook accounts fetched. Started: #{started.to_s(:db)} Duration: #{duration}"
     # for cronjob log:     
     puts msg      
     level = ((size-count)/2.0).round % size
     # log_error msg,level
     
  end
  
  def self.retrieve_extended sincedate=nil
     started = Time.now.utc
     count = 0
     no_count = 0
     begin
       records = self.where(["id in (?)",more_history_data_ids]).to_a
       records.each_with_index do |a,i|
         if sincedate
           a.since_date = sincedate
         end
         if a.retrieve
           count += 1
           Rails.logger.info "Finished #{a.id} Sleep 5 seconds for next account"
           sleep 5
         end
       end
     rescue Exception => ex
       logger.error "   retrieve #{ex.message}"  
     end
     ended = Time.now.utc
     size = records.size - no_count
     total_seconds=(ended-started).to_i
     duration=Time.at(total_seconds).utc.strftime("%H:%M:%S")
     msg = "#{count} out of #{size} Facebook accounts fetched. Started: #{started.to_s(:db)} Duration: #{duration}"
     # for cronjob log:     
     puts msg
  end
  
  # finish 1 years data for voiceofamerica: 1.5hours
  # 
  def retrieve
    # TODO remove !!self.graph after run once
    if self.new_item? # !!self.graph
      @since_date = 6.months.ago
    end
    @bulk_insert_array = []
    @bulk_update_hash = {}
    puts "  retrieve #{self.id} #{since_date}"
    since = since_date
    hasta = until_date
    started=Time.now.strftime("%Y-%m-%d %H:%M:%S .%L")
    success = nil
    while (hasta - since_date) >= back_to_date
      since = hasta - back_to_date
      success = do_retrieve(since, hasta)
      # yes just minus 1 second, becomes the end of previous day
      hasta = since - 1
    end
    if !@bulk_update_hash.blank?
      # FbPost.update_bulk! [:replies_to_comment,:post_created_time], @bulk_update_hash
      FbPost.update_bulk! @bulk_update_hash
      @bulk_update_hash = {}
    end
    if !@bulk_insert_array.empty?
      # puts "  retrieve call FbPost.import_bulk!"
      FbPost.import_bulk! @bulk_insert_array
      @bulk_insert_array = []
    end
    save_posts_details
    self.update_attributes :new_item=>false,:status=>success,:updated_at=>DateTime.now.utc
    begin
      # for today only
      daily_aggregate_data
    rescue Exception=>ex
      logger.error "  retrieve daily_aggregate_data #{ex.message}"
    end
    begin
      # for past 7 days if no argument 
      aggregate_data_daily
    rescue Exception=>ex
      logger.error "  retrieve aggregate_data_daily #{ex.message}"
    end
    # create additional fb_pages if neccessary
    # aggregate_data 1,'day', true
    # recent_page available after aggregate_data
    save_lifetime_data
    ended=Time.now.strftime("%Y-%m-%d %H:%M:%S .%L")
    puts "  id #{self.id} finished retrieve #{started} - #{ended} "
    STDOUT.flush
  end

  def do_retrieve(since=7.days.ago, hasta=DateTime.now.utc, rabbit=false)
    ret = false
    started = DateTime.now.utc
    puts " do_retrieve #{since} - #{hasta}"
    STDOUT.flush
    @num_attempts = 0
    begin
      @num_attempts += 1
      objectname = self.object_name.split("/").last.gsub(/\?$/, "")
      posts = graph_api.get_connections(objectname, "posts", {:fields=>"id,actions,comments,created_time",:limit=>QUERY_LIMIT, :since=>since, :until=>hasta}, { request: { timeout: 10 } }).to_a
      ret = true
    rescue Exception,Koala::Facebook::ClientError=>error
      puts " graph_api.get_connections() #{error.message}"
      logger.debug "  ClientError retrieve #{error.backtrace}" 
      if @num_attempts < self.max_attempts
        sleep RETRY_SLEEP
        retry
      end
    rescue StandardError=>error
      # log_fail "graph_api.get_connections() #{error.message}"
      # delayed_do_retrieve(since, hasta)
      puts "   retrieve #{error.message}" 
      logger.debug "  Exception retrieve #{error.backtrace}" 
    end
    if ret  
      begin     
        process_posts(posts)
        if !!rabbit
          send_mq_message(rabbit)
        else
          ## save_post_details
          #  save_posts_details
        end
      rescue Exception=>error
        # log_fail "process_posts() #{error.message}"
        # delayed_do_retrieve(since, hasta)
        puts " do_retrieve #{error.message}"
        logger.debug "   retrieve #{error.backtrace}"
      end
    end
    puts "   #{self.id} retrieve #{ret}"
    ret
  end
  
  def delayed_do_retrieve(since=7.days.ago, hasta=DateTime.now.utc, rabbit=false)
    retrieve since, hasta, rabbit
  end
  handle_asynchronously :delayed_do_retrieve,:run_at => Proc.new { SCHEDULED_DELAY }
  
  def process_posts(posts)
    return true if !posts || posts.empty?
    logger.info "Process posts size: #{posts.size}"
    STDOUT.flush
#    self.fb_posts.reload
    last_created_time = DateTime.now.utc
    posts.each do |f|
      last_created_time= DateTime.parse(f['created_time'])
      if last_created_time > since_date.beginning_of_day
        replies_to_comment = get_replies_to_comment(f)          
        # no good way to tell a post is the original
        post_type = 'original' 
        insert = {:account_id=>self.id,
                  :post_id=>f['id'],
                  :replies_to_comment =>replies_to_comment,
                  :post_created_time=>last_created_time.to_s(:db)}
                  
        # dbpost = self.fb_posts.find_by(:post_id=>f['id'])
        dbpost =  my_account_posts.detect{|po| po.post_id==f['id']}
        if dbpost
          @bulk_update_hash[dbpost.id] = insert
          # dbpost.update_attributes insert
        else
          @bulk_insert_array << insert
        end
      else
        logger.debug "  process_posts #{last_created_time.to_s(:db)} < #{since_date.to_s(:db)}"
      end
    end

    # fetch lifetime page likes
    # daily_aggregate_data
    # fetch posts from next page
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
            # log_fail "Tried #{@num_attempts} times. #{error.message}", 5
            feeds = []
          end
        end
        begin
          process_posts(feeds)
        rescue Exception=>error
          log_error "  process_posts #{error.message}"
          # log_fail "by process_posts #{error.message}", 2
        end
      end
    end
  end
  
  # this mothod is run by admin manually
  def self.save_post_details sincedate=90.days.ago
    arr = FacebookAccount.where("is_active=1").to_a
    arr.each do | acc |
      acc.since_date = sincedate
      acc.save_post_details
      puts "  processed #{acc.object_name}  #{acc.id}"
      STDOUT.flush
    end
  end
  
  def save_post_details
     count = 0
     total_processed = 0
     # myposts = FbPost.select('id, post_id').where(account_id: self.id).
     #   where("post_created_time > '#{since_date}'").to_a
     my_account_posts = self.fb_posts.reload.select('id,post_id,post_created_time').where("post_created_time > '#{@since_date}'").to_a
     my_account_posts.each do |post|
       count += 1
       total_processed += 1
       if count > 15
         puts "Sleep 1"
         count = 0
         sleep 1
       end
       @num_attempts = 0
       data = {}
       begin
         @num_attempts += 1   
         # insights = graph_api.graph_call("v2.2/#{post.post_id}/insights/post_story_adds_by_action_type")
         # data=insights[0]['values'][0]['value'] rescue {}
         data = graph_api.get_object(post.post_id, :fields => "shares,likes.summary(true),comments.summary(true)")
       rescue Koala::Facebook::ClientError, Timeout::Error=>error
         if @num_attempts < self.max_attempts
           sleep RETRY_SLEEP
           retry
         else
           # log_fail "Tried #{@num_attempts} times. #{error.message[0..200]}", 5
           log_error error.message
         end
       rescue Exception=>error
         log_error error.message
         logger.error "FB Account: #{self.id} - save_post_details Exception post #{post.post_id}"
       end
       completed = ((total_processed.to_f / my_account_posts.size) * 100).to_i
       logger.debug "#{completed} % completed" if ((total_processed % 10)==0 )
       unless data.empty?
         # like_count = data['like']
         # comment_count = data['comment']
         # share_count = data['share']
         begin
           like_count = 0
           comment_count = 0
           share_count = 0
           if data['likes']
             like_count=data['likes']['summary']['total_count']
           end
           if data['comments']
             comment_count = data['comments']['summary']['total_count']
           end
           if data['shares']
             share_count = data['shares']['count']
           end
           post.update_attributes :likes=>like_count,
             :comments=>comment_count,
             :shares=>share_count
         rescue Exception=>ex
           log_error "  #save_post_details #{ex.message}"
           logger.error "    #{ex.backtrace}"  
         end
       else
         logger.debug "No public data for post #{post.post_id}"
       end
     end
     aggregate_data 1,'day', true
     # recent_page available after aggregate_data
     save_lifetime_data
  end

  def save_posts_details
     count = 0
     total_processed = 0
     results = []
     @posts_update = {}
     my_account_posts = self.fb_posts.reload.select('id,post_id,post_created_time').where("post_created_time > '#{@since_date}'").to_a
     post_ids = my_account_posts.map(&:post_id)
     puts " POSTS count: #{post_ids.size}"
     post_ids.each_slice(50) do | ids |
       @num_attempts = 0
       begin
         @num_attempts += 1
         results = graph_api.get_objects(ids, :fields => "id,shares,likes.summary(true),comments.summary(true)") 
       rescue Koala::Facebook::ClientError, Timeout::Error, Exception=>error
         if @num_attempts < self.max_attempts
           sleep RETRY_SLEEP
           retry
         else
           log_error error.message
         end
       end
       puts "  Results count: #{results.size}"
       results.each do | result | 
         unless result.empty?
           begin
             data = result.last
             like_count = 0
             comment_count = 0
             share_count = 0
             if data['likes']
               like_count=data['likes']['summary']['total_count']
             end
             if data['comments']
               comment_count = data['comments']['summary']['total_count']
             end
             if data['shares']
               share_count = data['shares']['count']
             end
             post = my_account_posts.detect{|a| a.post_id == data['id']}
             attr = {:likes=>like_count,:comments=>comment_count,:shares=>share_count}
             @posts_update[post.id] = attr
             # post.update_attributes attr
           rescue Exception=>ex
             log_error "  #save_posts_details #{ex.message}"
             logger.error "    #{ex.backtrace}"  
           end
         else
           logger.debug "No public data for post #{post.post_id}"
         end
       end
     end
     
     if !@posts_update.empty?
       FbPost.update_bulk! @posts_update 
       @posts_update = {}
     end
     # aggregate_data 1,'day', true
     # recent_page available after aggregate_data
     # save_lifetime_data
  end
  
  def self.save_lifetime_data
     self.where(is_active: 1).each do |record|
       record.save_lifetime_data
     end
  end
  
  def save_lifetime_data
    begin
      options = {}
      # link = "https://graph.facebook.com/?id=#{self.obj_name}"
      # response = self.class.fetch link
      # json = JSON.parse response.body
      json = graph_api.get_object object_name, 
         :fields=>"picture,is_verified,description,name,likes,location,link,talking_about_count, website"

      talking_about = json['talking_about_count'].to_i
      if json['website']
        websites = json['website'].split(' ')
      else
        websites = []
      end
      options[:platform_type] = 'FB'
      options[:display_name] = json['name']
      if json['description']
        options[:description] = json['description']
      end
      if json['picture']['data']
        options[:avatar] = json['picture']['data']['url']
      end
      options[:total_followers] =json['likes'].to_i
      if json['location']
        options[:location] = json['location']
      end
      if json['link']
      options[:url] = json['link']
      end
      if json['is_verified']
        options[:verified] = json['is_verified']
      else
        options[:verified] = 0
      end
      self.update_profile options
      
    rescue Exception=>error
      log_error " 1 save_lifetime_data #{error.message}"
      logger.debug error.backtrace
      return
    end
       
    shares = 0
    begin
      websites.each do |website|
        unless website =~ URI::regexp(%w(http https))
          next
        end
        if !website.match(/http:\/\/|https:\/\//)
          website = "http://#{website}"
        end
        link = "https://graph.facebook.com/?id=#{website}"
        begin
          response = self.class.fetch link
          json = JSON.parse response.body
          shares += json['shares'].to_i
        rescue Exception=>ex
          logger.error "FacebookAccount#save_lifetime_data #{ex.message}"
        end
      end
    rescue Exception=>error
      logger.error "  2 save_lifetime_data #{error.message}"
      logger.debug "  #{error.backtrace}"
    end
    # @page = self.account.graph_api.get_object self.obj_name
    res = FbPage.where(:account_id=>self.id).select("sum(comments) AS comments").first
    hash = {:total_likes=>options[:total_followers], 
            :total_comments => res.comments,
            :total_talking_about=>talking_about}
    hash[:total_shares]=shares if shares > 0
    # puts " AAAA #{hash.inspect}"
    today_page.update_attributes hash
  end
  
  def get_replies_to_comment(f)
    replies_to_comment = 0
    if f['comments'] && f['comments']['data']
      f['comments']['data'].each do |comm|
        comment_id = comm['id']
        @num_attempts = 0            
        begin
          @num_attempts += 1
          comments = graph_api.api("#{comment_id}/comments") 
          if comments['data'] 
            replies_to_comment += comments['data'].size
          end
        rescue Koala::Facebook::ClientError=>error
          if @num_attempts < self.max_attempts
            sleep RETRY_SLEEP
            retry
          else
            log_fail "Tried #{@num_attempts} times. #{error.message}", 5
          end
        end
      end
    end
    # logger.debug "  get_replies_to_comment #{replies_to_comment}"
    replies_to_comment
  end

  def since_date=(date)
    @since_date=date
  end
  
  def since_date
    if !@since_date
      since_str = Facebook.config[:since_date] || "7.days.ago"
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
    @back_to_date ||=
      # since_str = Facebook.config[:since_date]  || "7.days.ago"
      # since_str.match /(\d+\.\w+)\.ago/
      # @back_to_date = (instance_eval $1).to_i
      (Time.zone.now - since_date.end_of_day)
  end
  def recent_posts
    @recent_posts = fb_posts.where("post_created_time > '#{since_date.to_s(:db)}'")
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
  
  def today_fbpage
    d = DateTime.now.utc
    @today_fbpage ||= Fbpage.where(account_id: self.id).
         where(post_created_time: (d.beginning_of_day..d.end_of_day)).
         order('updated_at desc').first
    if !@today_fbpage
      @today_fbpage = Fbpage.create account_id: self.id,
         post_created_time: DateTime.now.utc.middle_of_day
      @today_fbpage.object_name = self.object_name
    end
    @today_fbpage
  end
  def today_page
    d = DateTime.now.utc
    @today_page ||= FbPage.where(account_id: self.id).
         where(post_created_time: (d.beginning_of_day..d.end_of_day)).
         order('updated_at desc').first
    if !@today_page
      @today_page = FbPage.create account_id: self.id,
         post_created_time: DateTime.now.utc.middle_of_day
      @today_page.object_name = self.object_name
    end
    @today_page
  end
  def yesterday_page
    d = DateTime.now.utc - 1.day
    @yesterday_page ||= FbPage.where(account_id: self.id).
         where(post_created_time: (d.beginning_of_day..d.end_of_day)).
         order('updated_at desc').first
  end
  def find_account_country loc
    cn = nil
    if loc
      begin
        street=loc['street']
        city=loc['city']
        country=loc['country']
        cn = Country.find_by name: country
      rescue Exception=>ex
      
      end
    end
    cn
  end
  
=begin
    # a yahoo post
    obj="7040724713_10153243363174714" 
    a=FacebookAccount.find 7
    z=a.graph_api.get_object(obj, :fields => "shares,likes.summary(true),comments.summary(true)")
    z['likes']['summary']['total_count']
    z['comments']['summary']['total_count']
    z['shares']['count']
=end
  def app_token
    uri = URI.parse Facebook.config[:canvas_url]        
    canvas_url = uri.host
    # where("page_access_token is not null")
    @tokens ||= AppToken.where("platform='Facebook'").where("client_id is not null").to_a
    @access_token = @tokens.sample # [self.id % @tokens.size]
  end
  
=begin
# find which FB accounts not accessible
aa=FacebookAccount.where(media_type_name: 'FacebookAccount',is_active: true).to_a
aa.each do |a|
  begin
    a.graph_api.get_object a.object_name
  rescue Exception=>ex
    Rails.logger.debug " AAA #{a.object_name} - #{ex.message}"
  end
end
=end

  def graph_api(access_token=nil)
    Koala.config.api_version = "v2.5"
    Koala.http_service.http_options = {request: {open_timeout: 3, timeout: 5}}
    if !access_token
      access_token = self.app_token.get_access_token
    end
    @graph_api = Koala::Facebook::API.new(access_token)
  end
  
  def self.aggregate_data_daily start_date=1.month.ago, end_date=Time.now
    if !start_date
      start_date = 3.months.ago
    end
    if !end_date
      end_date = Time.zone.now
    end
    start_date = Time.zone.parse start_date if String ===  start_date
    end_date = Time.zone.parse end_date if String ===  end_date
     records = select('id, object_name,new_item').where("is_active=1").to_a
     records.each do |record|
        puts " aggregate_data_daily for #{record.object_name}" 
        record.aggregate_data_daily start_date, end_date
     end
  end
  
  def self.daily_aggregate_data
     records = select('id, object_name,new_item').where("is_active=1").to_a
     records.each do |record|
        puts " daily_aggregate_data for #{record.id} #{record.object_name}"
        begin 
          record.daily_aggregate_data
        rescue Exception=>ex
          logger.error "daily_aggregate_data for #{record.id} #{ex.message}"
        end
     end
  end
  #
  # run it daily to update today's fb_pages and fbpages
  # total_likes and total_talking_about are set for 
  # today's fb_pages
  # total_likes and total_talking_about, as well as likes, shares,
  # comments summary over 1 year's post data are set for
  # today's fbpages.
  # 
  # total_likes and total_talking_about are from the 
  # User's Facebook home page
  # likes, shares etc. are from summary over 1 year's post data
  # from fb_posts table
  # Because there was bug in save_post_details, certain post_id
  # does not allow to get likes, shares etc. details and
  # throws exception. save_post_details stopped at such post_ids
  # and thus the daily aggragated data is incomplete.
  # Now the bug is fixed, and the numbers of likes, shares, comments 
  # on and after today (2015-04-21) will be larger then the
  # dates before (2015-04-21).
  # In ReportsController#get_stat_class, use FbStat.new
  # to use table fb_pages data
  # for now. Let daily_aggregate_data run for another 3 weeks
  # we may switch to FbStatNew.new to use table fbpages data
  #
  # This is for life time data for today
  def daily_aggregate_data
    data = FbPost.select("count(*) AS post_count,sum(likes) as likes, sum(comments) as comments, sum(shares) as shares,sum(replies_to_comment) as replies_to_comment").
                  where(account_id: self.id).to_a.first
    if data
       z = self.graph_api.get_object self.object_name
       options = {:likes=>data.likes, 
                 :comments=>data.comments,
                 :shares=>data.shares,
                 :posts => data.post_count,
                 :replies_to_comment => data.replies_to_comment
                }
        if z['likes']
          options[:total_likes]=z['likes']
          today_page.total_likes=z['likes']
        end
        if z['talking_about_count']
          options[:total_talking_about] = z['talking_about_count']
          today_page.total_talking_about=z['talking_about_count']
        end
        curr_date = Time.zone.now.middle_of_day
        options[:post_created_time] = curr_date
        if today_page.total_likes && yesterday_page && yesterday_page.total_likes
          today_page.fan_adds_day =today_page.total_likes - yesterday_page.total_likes
        end
        today_page.update_attributes options
        today_fbpage.update_attributes options  # for table fbpages
        logger.debug "  daily_aggregate_data for #{curr_date.to_s(:db)}"
    else
       logger.debug "  daily_aggregate_data NOT RECORDS for  "
    end
  end
  #
  # for start_date thru end_date fb_pages, default for 7.days
  # set likes, shares etc for each day
  def aggregate_data_daily start_date=7.days.ago, end_date=Time.now
    start_date = Time.zone.parse start_date if String ===  start_date
    end_date = Time.zone.parse end_date if String ===  end_date
    current_date = start_date.beginning_of_day
    # reload @my_account_pages
    my_account_pages(true)
    my_arr = []
    my_posts = fb_posts.select("DATE_FORMAT(post_created_time,'%Y%m%d') AS post_date,likes, comments, shares, replies_to_comment").where("post_created_time > '#{current_date}'").to_a       
    while current_date < end_date do
      logger.debug " aggregate_data_daily for #{current_date.to_s(:db)}"
      posts= my_posts.select{|po| po.post_date == current_date.strftime('%Y%m%d')}
      
=begin
      data = FbPost.select("count(*) AS post_count,sum(likes) as likes, sum(comments) as comments, sum(shares) as shares,sum(replies_to_comment) as replies_to_comment").
                    where(account_id:   self.id).
                    where(post_type: 'original').
                    where(post_created_time:  current_date..current_date.end_of_day).to_a.first
=end
       if posts.size > 0
         options = construct_sum posts
         rec = my_account_pages.detect{|pa| pa.post_date==current_date.strftime('%Y%m%d')}
         if rec
           rec.update_attributes options
         else
           options[:post_created_time] = created_time.middle_of_day
           options[:account_id] = self.id
           options[:object_name] = self.object_name
           rec = FbPage.create options
         end
       else
         #   logger.debug " aggregate_data_daily NOT RECORDS for #{start_date.to_s(:db)} .. #{end_date.to_s(:db)}"
       end
       current_date += 1.day
    end
  end
  # return hash
  def construct_sum posts
    options = {:posts => posts.size}
    [:likes, :comments, :shares, :replies_to_comment].each do | col |
      options[col] = posts.sum{|e| e.send(col).to_i} 
    end
    options
  end
  
  def self.bulk_update_posts columns, data
    started = Time.now
    columns.each do | col |
      ids_hash = {}
      data.keys.each do | id |
        ids_hash[id] = data[id][col] if data[id][col]
      end
      self.bulk_update_column 'fb_posts', 'id', "#{col}", ids_hash
    end
=begin
    FbPost.transaction do
      puts "  process_posts call FbPost.update"
      FbPost.update(data.keys, data.values)
    end
=end
    ended = Time.now
    duration = ended.to_i - started.to_i
    puts "#{data.keys.size} posts updated in #{duration} seconds"
  end
        
  protected
  
  def my_account_pages(load=false)
    if load
      @my_account_pages = self.fb_pages.reload.select("id,DATE_FORMAT(post_created_time,'%Y%m%d') AS post_date").where("post_created_time > '#{@since_date}'").to_a  
    else
      @my_account_pages ||= self.fb_pages.select("id,DATE_FORMAT(post_created_time,'%Y%m%d') AS post_date").where("post_created_time > '#{@since_date}'").to_a  
    end
  end
  def my_account_posts(load=false)
    if load
      @my_account_posts = self.fb_posts.reload.select("id,likes,comments,shares,replies_to_comment,post_id,post_created_time,DATE_FORMAT(post_created_time,'%Y%m%d') AS post_date").where("post_created_time > '#{@since_date}'").to_a
    else
      @my_account_posts ||= self.fb_posts.select("id,likes,comments,shares,replies_to_comment,post_id,post_created_time,DATE_FORMAT(post_created_time,'%Y%m%d') AS post_date").where("post_created_time > '#{@since_date}'").to_a
    end
  end
  # TODO not in use
  def find_or_create_page(options)
    created_time = options.delete :post_created_time
    begin_date = created_time.beginning_of_day
    end_date = created_time.end_of_day
    rec = my_account_pages.detect{|pa| pa.post_date==begin_date.strftime('%Y%m%d')}
    # rec = FbPage.where(account_id: self.id).where(post_created_time: (begin_date..end_date)).first
    if !rec
       rec = FbPage.create :account_id => self.id, 
             :post_created_time=>created_time.middle_of_day,
             :object_name => self.object_name
    end
    rec.update_attributes options
  end

  # TODO not in use
  def exist_posts
    @exist_posts ||= FbPost.all.map {|a| a.post_id}
  end
  
  def expire
  
  end
  
  def me  
    feeds=graph_api.graph_call("v2.5/me")
  end
  
  # period 1.day or 1.week or 1.month
  def lifetime_data number=1, unit="day"
    increment = instance_eval("#{number}.#{unit}")
    end_of_today = DateTime.now.utc.end_of_day
    
    # current_date = DateTime.now.utc.end_of_day
    current_date = end_of_today
    my_arr = []
    while current_date > min_post_date do
      end_of_ = current_date.end_of_day
      if end_of_ > end_of_today
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
    data = fb_pages.where(post_created_time: 
             (end_of.beginning_of_day..end_of.end_of_day)).
             first
  end
  # create fb_page and return aggregated data
  # period 1.day or 1.week or 1.month
  def aggregate_data number=1, unit="month", create_page=false
    increment = instance_eval("#{number}.#{unit}")
    end_of_today = DateTime.now.utc.end_of_day
    current_date = end_of_today
    my_arr = []
    @bulk_insert=[]
    @bulk_update={}
    while current_date > min_post_date do
      beginning_of_ = (current_date-increment+1.day).beginning_of_day.to_s(:db)
      end_of_ = current_date
      if end_of_ > end_of_today
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
       # find_or_create_page(options)

        options[:post_created_time] = current_date
        created_time = options[:post_created_time]
        begin_date = created_time.beginning_of_day
        end_date = created_time.end_of_day
        rec = FbPage.where(account_id: self.id).
                where(post_created_time: (begin_date..end_date)).first
        attr = {:account_id => self.id, 
                :post_created_time=>created_time.middle_of_day,
                :object_name => self.object_name}
        if rec
          @bulk_update[rec.id] =  attr
        else
          @bulk_insert << attr
        end
    
      end
      # current_date = current_date - increment
      current_date = current_date - 1.day
    end
    if !@bulk_update.blank?
      FbPage.transaction do
        FbPage.update @bulk_update.keys, @bulk_update.values
        @bulk_update = {}
      end
    elsif !@bulk_insert.empty?
      FbPage.transaction do
        FbPage.import_bulk! @bulk_insert
        @bulk_insert = []
      end
    end
    my_arr.reverse
  end

  #
  # return FbPost object
  def select_aggregated_data beginning_of, end_of
    data = recent_posts.select("count(*) AS post_count,sum(likes) as likes, sum(comments) as comments, sum(shares) as shares,sum(replies_to_comment) as replies_to_comment").
        where(post_type: 'original').
        where(post_created_time: (beginning_of..end_of)).
        first
  end
  
  def collect_started
    begin
      Fbpage.select("min(created_at) as created_at").where(account_id: self.id).first.created_at.to_s(:db)
    rescue Exception=>ex
      'N/A'
    end
  end
  
end
=begin
  "963149653720643" is a video id
  a.graph_api.get_object "963149653720643", 
   {:fields=>
     "id,created_time,sharedposts,from,
     likes,embeddable,content_category,title,status"}
  
  def post_details post_id
    data = graph_api.get_object(post_id, :fields => "shares,likes.summary(true),comments.summary(true)")
    feed = graph_api.get_object('/' + post_id + '/likes?limit=1000')
    like_id="1422452251401888"
    likes = graph_api.get_object like_id
    while feed.size > 0
      count += feed.size
      feed = feed.next_page rescue []
    end
  end
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
  
  
  def send_mq_message rabbit
    payload = {:account_id => self.id, :date=>Time.zone.now.to_s(:db)}.to_yaml
    rabbit.channel.default_exchange.publish(payload,
            :type        => "save_post_details",
            :routing_key => "amqpgem.examples.patterns.command")
    rabbit.connection.close
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
  
  
  def recent_page
    @recent_page = fb_pages.order("post_created_time desc").first
  end

  def graph
    graph_api
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
        @insights=graph_api.graph_call("v2.3/#{self.obj_name}/insights")
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
     @insight_fans=graph_api.graph_call("v2.2/#{self.obj_name}/insights/page_fan_adds/day?since=#{duration.to_i}")
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
  
  # copy accounts from smdata to GovDash
  def copy
     Account.all.each do |a|
       hsh={}
       hsh[:name]=a.name
       hsh[:description]=a.description
       hsh[:object_name]=a.object_name
       hsh[:media_type_name]=a.media_type_name
       hsh[:account_type_id]=a.account_type_id if a.account_type_id
       hsh[:contact]=a.contact if a.contact
       hsh[:sc_segment_id]=a.sc_segment_id if a.sc_segment_id
       Rails.logger.info "acc=Account.find_or_create_by media_type_name: '#{a.media_type_name}', object_name: '#{a.object_name}'"
       Rails.logger.info "acc.update_attributes(#{hsh})"
    end; nil;
    # test if FacebookAccount copied
    # in smdata 
    Account.where("media_type_name='FacebookAccount'").select("distinct object_name").map(&:object_name)
    old_fb=["Sawa", "alhurra", "voaindonesia", "parazitparazit", "voalearningenglish", "voakhmer", "voiceofamerica", "VoA.Burmese.News", "voaurdu", "voapersian", "VOATiengViet", "DuniaKita", "voapashto", "voahausa", "KarwanTV", "VOAStraightTalkAfrica", "OnTenOnTen", "voadari", "voaamharic", "voastudentu", "zeriamerikes", "oddidevelopers", "alyoumshow", "RadioSvoboda.Org", "radiosvoboda", "radio.farda", "AzadiR", "mashaalradio", "azadiradio", "radiosvobodakrym.org", "rfacambodia", "RadioFreeAsia", "RFA-Burmese/39218993127", "RFAVietnam", "cantonese.rfa", "LaosRFA", "RFAChinese", "rfa.tibetan", "Erkin-Asiya-Radiosi/106605925076", "RFA-Korean/117459698841", "martinoticias", "1800Online", "voacantonese", "voachina", "voadeewa", "LaVoixdelAmerique", "voalao", "voasomali1", "LaVozdeAmerica", "voatibetan", "voa.azerbaijani", "voabangla", "studiowashington", "amerikiskhma", "RadiyoyacuVOA", "glasnaamerika", "voalivetalk", "voaportugues", "voakurdish", "otvorenistudio", "voaswahili", "voa-tigrigna", "chastime", "voa.uzbek"]
    # in GovDash    
    new_fb=Account.where("media_type_name='FacebookAccount'").where(["object_name in (?)", old_fb])
    old_fb.size == new_fb    
    # test if TwitterAccount copied
    # in smdata 
    Account.where("media_type_name='TwitterAccount'").select("distinct object_name").map(&:object_name)
    old_tw=["GolosAmeriki", "VOA_News", "VOAIran", "VOALearnEnglish", "voaindonesia", "chastime", "voachina", "VOANoticias", "voahausa", "voakhmer", "URDUVOA", "VOATurkish", "VOA_Somali", "zeriamerikes", "Voaburmese", "VOAAmharic", "VOAPashto", "voadeewa", "VOADariAfghan", "radiosvoboda", "radiosawa", "alhurranews", "alyoum", "SvobodaRadio", "RadioFarda_", "RadioAzadi", "svaboda", "RadioAzadliq", "iraqhurr", "RSE_Balkan", "Radio_Azattyk", "ozodlik", "RFA_Chinese", "DaiAChauTuDo", "RadioFreeAsia", "cantonese", "khmernews", "burmesenews", "laonews", "uyghurnews", "rfatibet", "koreannews", "martinoticias", "reportacuba", "MartiTempranito", "convozpropiarm", "@testme", "voaurdu", "VOABosnian", "VOAMacedonian", "Otvorenistudio", "VOAArmenian", "voaazeri", "voage", "AmerikaOvozi", "voacantonese", "VOA_Korean", "voa_thai", "VOA_Tibet_News", "VOATiengViet", "VOABANGLA", "VOAAfaanOromoo", "VOAFrench", "RadiyoyacuVOA", "Studio7VOA", "VOAPortugues", "VOASwahili", "VOATigrigna", "VOAKreyol", "VOA_Kurdish", "RFE_Kosova", "armenialiberty", "CurrentTimeTv"]
    # in GovDash    
    new_tw=Account.where("media_type_name='TwitterAccount'").where(["object_name in (?)", old_tw])
    old_tw.size == new_tw
    
    tw=new_tw.map(&:object_name)
    old_tw-tw=["chastime", "voadeewa", "radiosvoboda", "RadioFreeAsia"]
  end
  
  def clean_day_page a, date, pages
     return if pages.empty?
     to_delete = []
     page_class = pages.first.class
     while (date > 21.days.ago)
       if pages.size > 1
         pages[1..-1].each do |p|
           puts " delete #{a.id}: Date #{date.to_s(:db)}"
           to_delete << p.id
           #p.destroy!
         end
       else
         # puts " skip #{a.id}: Date #{date.to_s(:db)}"
       end
       date = date - 1.day
       pages = page_class.where(account_id: a.id).
         # where("likes is null and comments  is null and  shares  is null").
         where(post_created_time: (date.beginning_of_day..date.end_of_day)).
         order("created_at desc").to_a
     end
     if !to_delete.empty?
       page_class.delete_all("id in (#{to_delete.join(',')})")
       puts "  #{pages[0].object_name} Deleted #{to_delete.size} from #{page_class.table_name}"
     else
       # puts "  Nothing to delete "
     end
  end
  
  def delete_rows
    FacebookAccount.where("id > 0").each do | a |
      date = Time.zone.now
      pages = FbPage.where(account_id: a.id).
         # where("likes is null and comments  is null and  shares  is null").
         where(post_created_time: (date.beginning_of_day..date.end_of_day)).
         order("created_at desc").to_a
     
      clean_day_page a, date, pages
      date = Time.zone.now
      pages = Fbpage.where(account_id: a.id).
         where(post_created_time: (date.beginning_of_day..date.end_of_day)).
         order("created_at desc").to_a
     
      clean_day_page a, date, pages
    end; nil

  end
  
=end
