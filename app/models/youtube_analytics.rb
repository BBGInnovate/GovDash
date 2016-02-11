class YoutubeAnalytics
  attr_accessor :query_result
  
  def initialize access_token, account_id, channel_id
    unless GoogleAccessToken === access_token
      p "  Should pass a GoogleAccessToken object to YoutubeAnalytics.new " 
    end
    @access_token = access_token
    @account_id =  account_id
    @channel_id = channel_id
    
    @query_result = OpenStruct.new
    @query_result.account_id = @account_id
    @query_result.channel_id = @channel_id
    @query_result.results = []
    @query_result.errors = {}
  end

=begin
  If your application makes all API requests from a single IP address
  (i.e. on behalf of your users) you should consider using the userIP
  or quotaUser parameters with each request to get full QPS quota 
  for each user.
=end
  def execute! parameters={}, api_method='analytics/v1/reports'
    @num_attempts = 0
    # parameters['prettyPrint'] = false
    # parameters['quotaUser'] = @channel_id
    unless parameters['ids']
      parameters['ids'] = "contentOwner==#{YoutubeConf[:content_owner]}"
    end
    unless parameters['filters']
    #  parameters['filters'] = "channel==#{@channel_id}"
    end
    unless parameters['fields']
      parameters['fields'] = 'columnHeaders,rows,nextPageToken,prevPageToken,tokenPagination'
    end
    endpoint = "https://www.googleapis.com/youtube/#{api_method}"
    url = "#{endpoint}?#{parameters.to_query}"  
    begin    
      @num_attempts += 1
      p url
      @access_token.refresh_token!
      res = RestClient::Request.execute(method: :get, url: url,
         timeout: 10, headers: {'Authorization' => "Bearer #{@access_token.token}"})

      query_result.results = process_result(JSON.parse(res.body))
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
      query_result.errors = JSON.parse(ex.response)
    end
    query_result
  end

  def process_result hash={}
    p hash
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
            attr['published_at'] = col
          end
          if column_names[table_head[ix]]
            # these columns are in yt_channels table
            attr[column_names[table_head[ix]]] = col
          else
            # attr[table_head[ix]] = col
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
