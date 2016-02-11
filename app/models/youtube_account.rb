class YoutubeAccount < Account
  has_many :yt_channels, foreign_key: :account_id
  has_many :yt_videos, foreign_key: :account_id
  
  BATCH_COUNT = 5000
  
  def self.config
     YoutubeConf
  end
  
  # run this only once
  def self.initial_load
    YoutubeAccount.where("is_active is not null").to_a.each do | yt |
      yt.initial_load
    end
  end
  
  def self.retrieve sincedate=nil, from_id=0, reversed=false
    started = Time.now.utc
    count = 0
    records = self.retrieve_records from_id
    if reversed
      records = records.reverse
    end
    # where("is_active=1").to_a
    range = "0..#{records.size-1}"
    if YoutubeConf[:retrieve_range] &&
          YoutubeConf[:retrieve_range].match(/(\d+\.\.\d+)/)
       range = $1
    end
    records[eval range].each_with_index do |a,i|
      if sincedate
        a.since_date = sincedate
      end
      a.retrieve
      count += 1
    end
    ended = Time.now.utc
    size = records.size
    total_seconds=(ended-started).to_i
    duration=Time.at(total_seconds).utc.strftime("%H:%M:%S")
    msg = "#{count} out of #{size} Youtube accounts fetched. Started: #{started.to_s(:db)} Duration: #{duration}"    
    puts msg     
  end

  def initial_load
    process_channel
    @bulk_insert = []
    started = Time.now
    i = channel.video_count
    channel.videos.each do |v|
      i -= 1
      begin
        # video = Yt::Video.new id: v.id
        hs = construct_hash(v)
        # v.update_attributes hs
        @bulk_insert << hs
        if @bulk_insert.size > BATCH_COUNT
          puts "  initial_load: upload data for #{@bulk_insert.size} videos"
          YtVideo.import_bulk! @bulk_insert
          @bulk_insert = []
        end
      rescue Exception=>ex
        logger.error "  #{self.class.name}#initial_load #{ex.message}"
      end 
      if ( (i % 100) == 0 )
        puts "  #{i} videos remain"
      end
    end
    puts "  initial_load: upload data for #{@bulk_insert.size} videos"
    YtVideo.import_bulk! @bulk_insert
    
    summarize
    
    ended = Time.now
    log_duration started, ended
    @bulk_insert = []
  end
  # handle_asynchronously :initial_load, :run_at => Proc.new {10.seconds.from_now }
  
  #
  # start_date is class Time or YYYY-mm-dd format
  #
  def query_channel
    channel_id = self.channel.id
    start_date = 8.years.ago
    if Time === start_date
      start_date = start_date.strftime('%Y-%m-%d')
    end
    end_date = Time.zone.now
    if Time === end_date
      end_date = end_date.strftime('%Y-%m-%d')
    end
    @options = {'start-date' => start_date,'end-date' => end_date}
    @options['metrics'] = 'likes,dislikes,shares,comments,views,subscribersGained,subscribersLost'
    # @options['metrics'] += ',estimatedMinutesWatched,averageViewDuration,averageViewPercentage'
    # @options['dimensions'] = 'day'
    # @options['ids'] = "contentOwner==#{YoutubeConf[:content_owner]}"
    # @options['filters'] = "channel==#{channel_id}"
    # @options['fields'] = 'columnHeaders,rows'
    # @options['prettyPrint'] = false
    # @options['quotaUser'] = channel_id
    
    result = nil
    begin
      access_token = GoogleAccessToken.last
      api = YoutubeAnalytics.new access_token, self.id, channel_id
      result = api.execute! @options
      logger.info result
      load_to_yt_channels result
    rescue => ex
      p ex.message
      p ex.backtrace
    end
    result
  end
  
  def load_to_yt_channels result
    channel_id = channel.id
    published = Time.now.middle_of_day
    today_channel = YtChannel.find_or_create_by account_id: self.id,
       channel_id: channel.id, published_at: published.to_s(:db)
    
    today_channel.subscribers = channel.subscriber_count
    today_channel.views = channel.view_count
    today_channel.comments = channel.comment_count
    today_channel.videos = channel.video_count
    today_channel.save
    @insert_array = []
    @update_hash = {}
    @mychannels = YtChannel.select("id, DATE_FORMAT(published_at,'%Y-%m-%d') AS published_at").
       where(account_id: self.id).
       where("published_at > '#{self.since_date.beginning_of_day.to_s(:db)}'").to_a
    begin
      result.results.each do | rec |
        now = Time.zone.now
        rec[:updated_at] = now
        ch = @mychannels.detect{|mc| mc.published_at == rec['published_at']} 
        if ch
          @update_hash[ch.id] = rec
        else
          rec['account_id'] = self.id
          rec['channel_id'] = channel_id
          rec['published_at'] = now.middle_of_day
          rec[:created_at] = now
          @insert_array << rec
        end
      end
    rescue => ex
      logger.error " load_to_yt_channels #{ex.message}"
    end
    if !@insert_array.empty?
      logger.debug @insert_array[0..1]
    #  YtChannel.import_bulk! @insert_array
      @insert_array = []
    end
    if !@update_hash.blank?
      logger.debug "@update_hash size = #{@update_hash.keys.size}"
    # YtChannel.update_bulk! @update_hash
      @update_hash = {}
    end
    
  end


  def retrieve
    # to prevent attack from the youtube.yml, such as
    # YoutubeConf[:since_date] = "Account.destroy_all"
    # 
    @bulk_insert = []
    @bulk_update = {}
    puts "Started #{self.class.name}#retrieve #{self.id}"
    begin
      process_channel
      my_videos = self.yt_videos.to_a
    rescue Exception=>ex
      logger.error ex.message
      return
    end
    should_break = 0
    started = Time.now
    changed_videos = []
    channel.videos.each do |v|
      old_v = my_videos.detect{|v| v.published_at.to_date == v.published_at.to_date}
      if !old_v || v.published_at.to_i > since_date.to_i
        begin
          hs = construct_hash(v)
          video = my_videos.select{|a| a.video_id == v.id}.first
          # video = YtVideo.find_by video_id: v.id
          if video
            # video.update_attributes hs
            @bulk_update[video.id] = hs
          else
            # self.yt_videos.create hs
            @bulk_insert << hs
          end
        rescue Exception=>ex
          logger.error "  #{self.class.name}#retrieve Id: #{self.id} Video Id: #{v.id}"
          logger.error "  #{self.class.name}#retrieve #{ex.message}"
        end
      else
        logger.debug "  Skip #{v.published_at.to_s(:db)}"
        should_break += 1
      end
      if should_break > 3
        break
      end
    end
    summarize since_date
    if !@bulk_insert.empty?
      YtVideo.import_bulk! @bulk_insert
      @bulk_insert = []
    end
    if !@bulk_update.blank?
      YtVideo.update_bulk! @bulk_update
      @bulk_update = {}
    end
    ended = Time.now
    log_duration started, ended
  end
  # handle_asynchronously :retrieve, :run_at => Proc.new {10.seconds.from_now }
  
  def summarize init_date=nil
    self.reload
    videos = self.yt_videos
    sql = "sum(comments) video_comments,sum(favorites) video_favorites,"
    sql += "sum(likes) video_likes,sum(views) video_views,"
    sql += " date_format(published_at, '%Y-%m-%d') AS date"
    my_videos = videos.select(sql).group('date').order('date ASC')
    # my_videos = YtVideo.where(account_id: self.id).
    #       select(sql).group('date').order('date ASC')
    
    if !init_date
      init_date = Time.parse(my_videos.first.date)
    end

    @channel_insert = []
    while init_date < DateTime.now.utc
      data = my_videos.select{|a| a.date == init_date.strftime('%Y-%m-%d')}.first
      if data
        # if no YtChannel is found for that day, then  use 
        # YtChannel.import!. Otherwise use
        # YtChannel.update_attributes
        summary_for_day init_date, data
        if @channel_insert.size > BATCH_COUNT
          logger.debug "  #{self.class.name}#summarize upload #{@channel_insert.size}"
          YtChannel.import_bulk! @channel_insert
          @channel_insert = []
        end
      else
        p "  No Videos for DAte #{init_date}"
        pre_day = init_date.middle_of_day - 1.day
        sql = "account_id=#{self.id} AND published_at in ('#{init_date.middle_of_day}', '#{pre_day}')"
      
        chs = YtChannel.where(sql).order("published_at desc").to_a
        if chs.size == 2
          subs = chs[0].subscribers.to_i - chs[1].subscribers.to_i
          subs = 0 if subs < 0
          chs[0].update_column :video_subscribers, subs           
        end
      end
      init_date += 1.day 
    end
    unless @channel_insert.empty?
      YtChannel.import_bulk! @channel_insert
      @channel_insert = []
    end
  end
  
  def channel
    if @channel
      return @channel
    end
    begin
      if self.respond_to?(:object_name_type) && self.object_name_type == 'channel_id'
        logger.debug "  Youtube find by ID"
        @channel = Yt::Channel.new id: object_name
      else
        logger.debug "  Youtube find by url"
        @channel = Yt::Channel.new url: "youtube.com/#{object_name}"
      end
      # if object_name is a channel_id then
      # @channel.id will throw exception
      @channel.id
      @channel
    rescue Exception=>ex
      logger.error "  channel #{ex.message}" 
      logger.debug "  Youtube find by id" 
      @channel = Yt::Channel.new id: object_name
    end
  end
  
  protected
  
  def construct_hash video
    hs = {:account_id => self.id,
          :video_id => video.id,
          :published_at => video.published_at.to_s(:db),
          :likes => video.like_count,
          :dislikes => video.dislike_count,
          :comments => video.comment_count,
          :views => video.view_count,
          :favorites => video.favorite_count}
  end

  def process_channel
    # create daily yt_channel based on created_at
    published = Time.now.middle_of_day
    yt_ch = YtChannel.find_or_create_by account_id: self.id,
       channel_id: channel.id, published_at: published.to_s(:db)
    begin
      yt_ch.subscribers = channel.subscriber_count
      yt_ch.views = channel.view_count
      yt_ch.comments = channel.comment_count
      yt_ch.videos = channel.video_count
      pre_day = (published-1.day).to_s(:db)
      # pre_ch = self.yt_channels.where("published_at = '#{pre_day}'").last
      pre_ch = YtChannel.find_by account_id: self.id,
                published_at: "'#{pre_day}'"
      if pre_ch
        subs = yt_ch.subscribers.to_i - pre_ch.subscribers.to_i
        subs = 0 if subs < 0
        yt_ch.video_subscribers = subs
      end
      self.update_profile
    rescue Exception=>ex
      logger.error "  process_channel #{ex.message}"
    end
    yt_ch.save
  end

  def find_account_country loc
    if loc && loc.size == 2
      cn = Country.find_by code: loc
    else
      nil
    end
  end
  
  def update_profile options={}
    # https://gdata.youtube.com/feeds/api/users no longer work
=begin
    begin
      # loc = "https://gdata.youtube.com/feeds/api/users/#{channel.username}"
      loc = "https://gdata.youtube.com/feeds/api/users/#{self.object_name}"   
      doc = Nokogiri::Slop open(loc)
      options[:location] = doc.xpath('//location').text
    rescue Exception=> ex
      logger.debug "1 YoutubeAccount#update_profile #{ex.message}"
      loc="https://www.youtube.com/channel/UCNZGxJAZ4H7r8E68L8sNPNw"
      doc = Nokogiri::HTML open(loc) 
      begin     
        username = doc.xpath("//meta[@property='fb:profile_id']/@content").first.text   
      rescue Exception=> ex 
        raise logger.debug "2 YoutubeAccount#update_profile #{ex.message}"
      end
    end
    options[:display_name] = doc.xpath('//title').text 
      # channel.title
    if channel.description
     options[:description] = doc.xpath('//content').first.text
        # channel.description
    end
    options[:avatar] = doc.xpath('//thumbnail').attr('url').text
      # channel.thumbnail_url
    options[:total_followers] = doc.xpath('//statistics').attr('subscribercount').text.to_i
       # channel.subscriber_count
       
=end
    if channel.username
      url = "https://www.youtube.com/user/#{channel.username}"
    else
      url = "https://www.youtube.com/channel/#{self.object_name}"
    end
        
    options[:platform_type] = 'YT'
    options[:url] = url
    if !account_profile || !account_profile.verified
      html=Nokogiri::HTML(open url)
      qualified = html.css("span.qualified-channel-title-badge").first
      if qualified
        txt = qualified.xpath('span').attr('aria-label').text
        if txt == 'Verified'
          options[:verified] = true
        else
          options[:verified] = false
        end
      end
    end  
    super 
  end
  
  def log_duration started, ended
    total_seconds = (ended - started)
    seconds = total_seconds % 60
    minutes = (total_seconds / 60) % 60
    hours = total_seconds / (60 * 60)
    duration = format("%02d:%02d:%02d", hours, minutes, seconds)
    puts " #{ended.to_s(:db)} Ended #{self.class.name}"
    puts " ID #{self.id} - Duration: #{duration}"
  end
  
  def my_yt_channels
    @my_yt_channels ||= self.yt_channels.to_a
  end 

  def summary_for_day init_date, data
    self.reload
    ch = my_yt_channels.select{|a| a.published_at == init_date.middle_of_day}.first
    # ch = YtChannel.find_by account_id: self.id,
    #               published_at: init_date.middle_of_day
    pre_day = init_date.middle_of_day - 1.day
    pre_ch = self.yt_channels.where("published_at = '#{pre_day}'").last
    # pre_ch = YtChannel.find_by account_id: self.id,
    #               published_at: "#{pre_day}"
    if !ch
      # new record
      attr = data.attributes
      attr.delete('id')
      attr.delete('date')
      attr.merge! "published_at" => "#{init_date.middle_of_day.to_s(:db)}",
        "account_id" => self.id,
        "channel_id" => self.channel.id
      if pre_ch
        subs  = attr["subscribers"].to_i - pre_ch.subscribers.to_i
        subs = 0 if subs < 0
        attr.merge! "video_subscribers" => subs              
      end
    
      @channel_insert << attr
      return
    end
    
    if pre_ch
      subs = ch.subscribers.to_i - pre_ch.subscribers.to_i
      subs = 0 if subs < 0
      ch.video_subscribers = subs
    end
=begin
    changed = false
    if ch.video_comments != data.video_comments
      ch.video_comments = data.video_comments
      changed = true
    end
    if ch.video_favorites != data.video_favorites
      ch.video_favorites = data.video_favorites
      changed = true
    end
    if ch.video_likes != data.video_likes
      ch.video_likes = data.video_likes
      changed = true
    end
    if ch.video_views != data.video_views
      ch.video_views = data.video_views
      changed = true
    end
=end
    ch.video_comments = data.video_comments
    ch.video_favorites = data.video_favorites
    ch.video_likes = data.video_likes
    ch.video_views = data.video_views
    ch.save if ch.changed?
  end
  
  def collect_started
    begin
      YtChannel.select("min(created_at) as created_at").where(account_id: self.id).first.created_at.to_s(:db)
    rescue Exception=>ex
      'N/A'
    end
  end
end
=begin
  video = Yt::Video.new id: '0dktCpsvxuw'
  video.title 
  video.like_count
  video.comment_count 
  video.view_count
  video.hd? #=> true
  video.annotations.count #=> 1
=end


