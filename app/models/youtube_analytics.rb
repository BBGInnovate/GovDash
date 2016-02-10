class YoutubeResult
  attr_accessor :account_id
  attr_accessor :channel_id
  attr_accessor :results
  
  def initialize account_id, channel_id, results=[]
    @account_id = account_id
    @channel_id = channel_id
    @results = results
  end
  
end


class YoutubeAnalytics 
  attr_accessor :results
  def initialize access_token=nil
    unless GoogleAccessToken === access_token
      p "  Should pass a GoogleAccessToken object to YoutubeAnalytics.new " 
    end
    @access_token = access_token
  end

=begin
  If your application makes all API requests from a single IP address
  (i.e. on behalf of your users) you should consider using the userIP
  or quotaUser parameters with each request to get full QPS quota 
  for each user.
=end
  def execute! parameters={}, api_method='analytics/v1/reports'
    @num_attempts = 0
    endpoint = "https://www.googleapis.com/youtube/#{api_method}"
    url = "#{endpoint}?#{parameters.to_query}"  
    begin
      parameters['filters'].split(';').each do | fil |
        if fil.match /channel==(.*)/
          @channel_id = $1
          @account_id = YtChannel.find_by(channel_id: @channel_id).id
          break
        end
      end
      
      @num_attempts += 1
      p url
      @access_token.refresh_token!
      res = RestClient::Request.execute(method: :get, url: url,
         timeout: 10, headers: {'Authorization' => "Bearer #{@access_token.token}"})

      YoutubeResult.new @account_id, @channel_id, process_result(JSON.parse(res.body))
    rescue => ex
      p "  get #{ex.message}"
      p "  get #{ex.backtrace}"
      p ex.response
      if should_retry(ex) && @num_attempts < 4
        p " Sleep #{3 ** @num_attempts} seconds"
        sleep 3 ** @num_attempts
        retry
      else
        nil
      end
      YoutubeResult.new @account_id, @channel_id
    end
  end

  def process_result hash={}
    json_input = hash.deep_symbolize_keys
    table_head = []
    json_input[:columnHeaders].each do | th |
      table_head << th[:name]
    end
    @results = []
    rows = json_input[:rows]
    if rows.size > 0
      p "   rows size #{rows.size}" 
      rows.each do | row |
        attr = {}
        row.each_with_index do | col, ix |
          if table_head[ix] == 'day'
            attr['date'] = col
          end
          if column_names[table_head[ix]]
            attr[column_names[table_head[ix]]] = col
          end
        end
        @results << attr
      end
    end
    @results
  end
  
  def column_names
    {'likes' => 'video_dislikes' , 'dislike' => 'video_dislikes',
     'shares' => 'video_favorites','comments' => 'video_comments',
     'subscribersGained' => 'video_subscribers',
     'views' => 'video_views'}
  end
  
  def should_retry ex
    if ex.response
      errors = JSON.parse(ex.response)
      errors['error']['errors'].each do |err|
        if err['domain'] == 'yt:quota'
          return true
        end
      end
    end
    false
  end
  
end
