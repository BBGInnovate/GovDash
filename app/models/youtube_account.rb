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
  
  def self.retrieve sincedate=nil, from_id=0
    started = Time.now.utc
    count = 0
    records = self.retrieve_records from_id
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
          YtVideo.import! @bulk_insert
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
    YtVideo.import! @bulk_insert
    
    summarize
    
    ended = Time.now
    log_duration started, ended
    @bulk_insert = []
  end
  # handle_asynchronously :initial_load, :run_at => Proc.new {10.seconds.from_now }
  
  def retrieve
    # to prevent attack from the youtube.yml, such as
    # YoutubeConf[:since_date] = "Account.destroy_all"
    # 
=begin
    arr = YoutubeConf[:since_date].split('.')
    n = arr[0].to_i
    if n == 0
      raise "  YoutubeAccount#retrieve incorrect YoutubeConf[:since_date] format"
    end
    unit = arr[1].match(/days|months/)
    unless unit
      raise "  YoutubeAccount#retrieve incorrect YoutubeConf[:since_date] format"
    end
    sincedate = eval("#{n}.#{unit}.#{arr[2]}")
=end
   
    @bulk_insert = []
    puts "Started #{self.class.name}#retrieve #{self.id}"
    
    process_channel
   
    my_videos = self.yt_videos.to_a
    @bulk_insert = []
    started = Time.now
    changed_videos = []
    channel.videos.each do |v|
      if v.published_at.to_i > since_date.to_i
        begin
          hs = construct_hash(v)
          video = my_videos.select{|a| a.video_id == v.id}.first
          if video
            video.update_attributes hs
          else
            self.yt_videos.create hs
          end
=begin
          @bulk_insert << hs
          if @bulk_insert.size > BATCH_COUNT
            puts "Process #{v.published_at.to_s(:db)}"
            bulk_import
            @bulk_insert = []
          end
=end
        rescue Exception=>ex
          logger.error "  #{self.class.name}#retrieve Id: #{self.id} Video Id: #{v.id}"
          logger.error "  #{self.class.name}#retrieve #{ex.message}"
        end
      else
        logger.debug "  Skip #{v.published_at.to_s(:db)}"
        break 
      end
    end

    summarize since_date
    
    ended = Time.now
    log_duration started, ended
    @bulk_insert = []
  end
  # handle_asynchronously :retrieve, :run_at => Proc.new {10.seconds.from_now }
  
  def summarize init_date=nil
    videos = self.yt_videos
    sql = "sum(comments) video_comments,sum(favorites) video_favorites,"
    sql += "sum(likes) video_likes,sum(views) video_views,"
    sql += " date_format(published_at, '%Y-%m-%d') AS date"
    my_videos = videos.select(sql).group('date').order('date ASC')
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
          YtChannel.import! @channel_insert
          @channel_insert = []
        end
      end
      init_date += 1.day 
    end
    
    unless @channel_insert.empty?
      YtChannel.import! @channel_insert
    end
    @channel_insert = []
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
  
  def bulk_import
    unless @bulk_insert.empty?
      begin
        YtVideo.import! @bulk_insert
      rescue Exception=>ex
        logger.error " #{self.class.name}#bulk_import #{ex.message}"
      end
    end
  end
  
  def process_channel
    # create daily yt_channel based on created_at
    published = Time.now.middle_of_day
    yt_ch = self.yt_channels.find_or_create_by account_id: self.id,
       channel_id: channel.id, published_at: published.to_s(:db)
    begin
      yt_ch.subscribers = channel.subscriber_count
      yt_ch.views = channel.view_count
      yt_ch.comments = channel.comment_count
      yt_ch.videos = channel.video_count
    rescue Exception=>ex
      logger.error "  process_channel #{ex.message}"
    end
    pre_day = (published-1.day).to_s(:db)
    pre_ch = self.yt_channels.where("published_at = '#{pre_day}'").last
    if pre_ch
      yt_ch.video_subscribers = (yt_ch.subscribers.to_i - pre_ch.subscribers.to_i)
    end
    self.update_profile
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
    puts " Duration: #{duration}"
  end
  
  def my_yt_channels
    @my_yt_channels ||= self.yt_channels.to_a
  end 

  def summary_for_day init_date, data
    ch = my_yt_channels.select{|a| a.published_at == init_date.middle_of_day}.first
    pre_day = init_date.middle_of_day - 1.day
    pre_ch = self.yt_channels.where("published_at = '#{pre_day}'").last
    
    if !ch
      # new record
      attr = data.attributes
      attr.delete('id')
      attr.delete('date')
      attr.merge! "published_at" => "#{init_date.middle_of_day.to_s(:db)}",
        "account_id" => self.id,
        "channel_id" => self.channel.id
      if pre_ch
        attr.merge! "video_subscribers" => 
                     attr["subscribers"].to_i - pre_ch.subscribers.to_i
      end
    
      @channel_insert << attr
      return
    end
    
    if pre_ch
      ch.video_subscribers = 
                     ch.subscribers.to_i - pre_ch.subscribers.to_i
    end
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
    ch.save if changed
  end
  
  def collect_started
    YtChannel.select("min(created_at) as created_at").where(account_id: self.id).first.created_at.to_s(:db)
  end
end


