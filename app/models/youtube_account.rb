class YoutubeAccount < Account

  attr_accessor :total_video_count
  
  has_many :yt_channels, :foreign_key=>:account_id
  has_many :yt_videos,  -> { order 'published_at desc' }, :foreign_key=>:account_id

  # run this only once
  def self.init_load
    YoutubeAccount.where("is_active is not null").to_a.each do | yt |
      yt.init_load
    end
  end
  
  def self.retrieve
    YoutubeAccount.where("is_active is not null").to_a.each do | yt |
      yt.retrieve
    end
  end
  
  def init_load
    process_channel
    process_load
  end
  
  def retrieve
    process
  end
  
  protected
  
  def channel
    @channel ||= 
       Yt::Channel.new url: "youtube.com/#{object_name}"
  end
  
  def process_load
    @bulk_insert = []
    
    started = Time.now
    Rails.logger.info " #{started.to_s(:db)} Started #{self.class.name}#process_load #{channel.video_count} Videos"
    total_video_count = channel.video_count
    i = 0
    channel.videos.each do |v|
      if i > total_video_count 
        break
      else
        i += 1
      end
      save_video v.id
      
      if ( (i % 10) == 0 )
        Rails.logger.debug "  Processed video # #{i}"
      end
      
    end
    
    unless @bulk_insert.empty?
      last_video_id = YtVideo.import! @bulk_insert
      v = YtVideo.find last_video_id
      ch = YtChannel.find_or_create_by channel_id: channel.id
      ch.published_at = v.published_at
      ch.save
    end
    ended = Time.now
    total_seconds = (ended - started)
    seconds = total_seconds % 60
    minutes = (total_seconds / 60) % 60
    hours = total_seconds / (60 * 60)
    duration = format("%02d:%02d:%02d", hours, minutes, seconds)
    Rails.logger.info " #{ended.to_s(:db)} Ended #{self.class.name}#process_load"
    Rails.logger.info " Duration: #{duration}"
        
    @bulk_insert = []
    
  end
  
  def save_video vid
    begin
      video = Yt::Video.new id: vid
      # v = YtVideo.find_or_create_by video_id: video.id
      hs = {:account_id => self.id,
            :channel_id => channel.id,
            :video_id => video.id,
            :published_at => video.published_at,
            :likes => video.like_count - video.dislike_count,
            :comments => video.comment_count,
            :favorites => video.favorite_count}
      @bulk_insert << hs
      video.published_at
    rescue Exception=>ex
      Rails.logger.error "  #{self.class.name}#save_video #{ex.message}"
      nil
    end 
  end

  #
  # Entry point
  # YoutubeAccount.process
  #
  def process
    init
    process_channel
    process_results
    
    Rails.logger.info " #{Time.now.to_s(:db)} Started #{self.class.name}#process #{@bulk_insert.size} videos"
    unless @bulk_insert.empty?
      last_video_id = YtVideo.import! @bulk_insert
      v = YtVideo.find last_video_id
      ch = YtChannel.find_by channel_id: channel.id
      ch.published_at = v.published_at
      ch.save
    end
    Rails.logger.info " #{Time.now.to_s(:db)} Ended #{self.class.name}#process"
    @bulk_insert = []
    
  end
  
  def process_channel
    yt_ch = YtChannel.find_or_create_by channel_id: channel.id
    yt_ch.account_id=self.id
    yt_ch.views = channel.view_count
    yt_ch.comments = channel.comment_count
    yt_ch.videos = channel.video_count
    yt_ch.subscribers = channel.subscriber_count
    yt_ch.save
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
end
