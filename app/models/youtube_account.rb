class YoutubeAccount < Account
  has_many :yt_channels, foreign_key: :account_id
  has_many :yt_videos, foreign_key: :account_id
  
  # run this only once
  def self.initial_load
    YoutubeAccount.where("is_active is not null").to_a.each do | yt |
      yt.initial_load
    end
  end
  
  def self.retrieve
    YoutubeAccount.where("is_active is not null").to_a.each do | yt |
      yt.retrieve
    end
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
        if @bulk_insert.size > 500
          say "  initial_load: upload data for #{@bulk_insert.size} videos"
          bulk_import
          @bulk_insert = []
        end
      rescue Exception=>ex
        logger.error "  #{self.class.name}#initial_load #{ex.message}"
      end 
      if ( (i % 20) == 0 || i < 10 )
        say "  #{i} videos remain", Logger::Severity::DEBUG
      end
    end
    say "  initial_load: upload data for #{@bulk_insert.size} videos"
    bulk_import
    ended = Time.now
    log_duration started, ended
    @bulk_insert = []
  end
  # handle_asynchronously :initial_load, :run_at => Proc.new {10.seconds.from_now }
  
  def retrieve
    # to prevent attack from the youtube.yml, such as
    # YoutubeConf[:since_date] = "Account.destroy_all"
    # 
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
    
    @bulk_insert = []
    say "Started #{self.class.name}#retrieve"
    
    process_channel
   
    @bulk_insert = []
    started = Time.now
    channel.videos.each do |v|
      if v.published_at.to_i > sincedate.to_i
        begin
          hs = construct_hash(v)
          video = YtVideo.find_or_create_by video_id: v.id
          video.update_attributes hs
=begin
          @bulk_insert << hs
          if @bulk_insert.size > 500
            say "Process #{v.published_at.to_s(:db)}"
            bulk_import
            @bulk_insert = []
          end
=end
        rescue Exception=>ex
          logger.error "  #{self.class.name}#initial_load #{ex.message}"
        end
      else
        logger.debug "  Skip #{v.published_at.to_s(:db)}"
        break 
      end
    end
    bulk_import
    ended = Time.now
    log_duration started, ended
    @bulk_insert = []
  end
  handle_asynchronously :retrieve, :run_at => Proc.new {10.seconds.from_now }

  protected
  
  def channel
    @channel ||=
       Yt::Channel.new url: "youtube.com/#{object_name}"
  end
  
  def construct_hash video
    hs = {:account_id => self.id,
          :video_id => video.id,
          :published_at => video.published_at.to_s(:db),
          :likes => video.like_count - video.dislike_count,
          :comments => video.comment_count,
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
    created = Time.now.beginning_of_day.to_s(:db)
    yt_ch = YtChannel.find_or_create_by channel_id: channel.id, created_at: created
    yt_ch.account_id=self.id
    yt_ch.views = channel.view_count
    yt_ch.comments = channel.comment_count
    yt_ch.videos = channel.video_count
    yt_ch.subscribers = channel.subscriber_count
    yt_ch.published_at = channel.published_at
    yt_ch.save
  end
    
  def log_duration started, ended
    total_seconds = (ended - started)
    seconds = total_seconds % 60
    minutes = (total_seconds / 60) % 60
    hours = total_seconds / (60 * 60)
    duration = format("%02d:%02d:%02d", hours, minutes, seconds)
    say " #{ended.to_s(:db)} Ended #{self.class.name}"
    say " Duration: #{duration}"
  end

end
=begin
  def save_video vid
    begin
      video = Yt::Video.new id: vid
      v = YtVideo.find_or_create_by video_id: video.id
      hs = {:account_id => self.id,
            :channel_id => channel.id,
            :video_id => video.id,
            :published_at => "#{video.published_at.to_s(:db)}",
            :likes => video.like_count - video.dislike_count,
            :comments => video.comment_count,
            :favorites => video.favorite_count}
      # @bulk_insert << hs
      v.update_attributes hs
      video.published_at
    rescue Exception=>ex
      Rails.logger.error "  #{self.class.name}#save_video #{ex.message}"
      nil
    end 
  end
  
  def init
    @bulk_insert = []
    @next_page_token = nil
    @last_published_at = nil
  end

  def process_results
    results  = fetch
    @next_page_token = results['nextPageToken']
    if @next_page_token
      @next_page_token = "&pageToken=#{@next_page_token}"
    end
    unless results.empty?
      results['items'].each do |item|
        vid = item['id']['videoId']
        @last_published_at = save_video vid
      end  
    end
    if @last_published_at && @last_published_at > eval(conf.since_date)
      process_results
    else
      @last_published_at
    end
  end
  
  def path
    endpoint="https://www.googleapis.com/youtube/v3/search"
    api_key = YoutubeConf[:api_key]
    "#{endpoint}?channelId=#{channel.id}&key=#{api_key}&maxResults=#{max_results}&order=date&part=snippet&type=video"
  end

  def fetch
    url = self.path
    if @next_page_token
      url = url + @next_page_token
    end
    uri = URI.parse(url)
    req = Net::HTTP::Get.new(uri)
    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true if uri.scheme == 'https'
    http.read_timeout = YoutubeConf[:read_timeout] || 60
    http.open_timeout = YoutubeConf[:open_timeout] || 60
    response=nil
    http.start do |h|
      response = h.request(req)
      case response
        when (Net::HTTPOK || Net::HTTPSuccess)
        else
          response.error!
      end
    end
    if response
      hsh = JSON.parse response.body
    else
      {}
    end
    
  end
  
  def max_results
    @max_results ||= YoutubeConf[:max_results] || 50
  end
=end

