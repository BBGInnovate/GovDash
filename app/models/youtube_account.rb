class YoutubeAccount < Account
  has_one :yt_channel, foreign_key: :account_id

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
        video = Yt::Video.new id: v.id
        # v = YtVideo.find_or_create_by video_id: v.id
        hs = {:yt_channel_id => self.yt_channel.id,
              :video_id => v.id,
              :published_at => video.published_at.to_s(:db),
              :likes => video.like_count - video.dislike_count,
              :comments => video.comment_count,
              :favorites => video.favorite_count}
        # v.update_attributes hs
        @bulk_insert << hs
      rescue Exception=>ex
        Rails.logger.error "  #{self.class.name}#initial_load #{ex.message}"
      end 
      if ( (i % 10) == 0 || i < 10 )
        Rails.logger.debug "  #{i} videos remain"
      end
    end
    
    bulk_import
    ended = Time.now
    log_duration started, ended
    @bulk_insert = []
  end
  
  def retrieve
    init
    @bulk_insert = []
    Rails.logger.info " #{Time.now.to_s(:db)} Started #{self.class.name}#process "
    
    process_channel
    process_results
    
    bulk_import
    
    Rails.logger.info " #{Time.now.to_s(:db)} Ended #{self.class.name}#process"
    @bulk_insert = []
    
  end
  
  protected
  
  def channel
    @channel ||=
       Yt::Channel.new url: "youtube.com/#{object_name}"
  end
  
  def bulk_import
    unless @bulk_insert.empty?
      begin
        YtVideo.import! @bulk_insert
        ch = YtChannel.find_or_create_by channel_id: channel.id
        date = @bulk_insert.first[:published_at]
        ch.update_attribute :published_at,date
      rescue Exception=>ex
        Rails.logger.error " #{self.class.name}#bulk_import #{ex.message}" 
      end
    end
  end
  
  
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
  
  def log_duration started, ended
    total_seconds = (ended - started)
    seconds = total_seconds % 60
    minutes = (total_seconds / 60) % 60
    hours = total_seconds / (60 * 60)
    duration = format("%02d:%02d:%02d", hours, minutes, seconds)
    Rails.logger.info " #{ended.to_s(:db)} Ended #{self.class.name}#process_load"
    Rails.logger.info " Duration: #{duration}"
  end
  
end
