require Rails.root.to_s + '/lib/read_stat_detail'

class YtStat
  include ReadStatDetail

  attr_accessor :min_subscribers, :max_subscribers
  
  # select data for one year
  # sum over month
  def get_select_trend_by_month start_date,myend_date, myaccounts
    if myend_date.day != myend_date.end_of_month.day
       myend_date = (myend_date - 1.month)
    end
    account_ids = myaccounts.map{|a| a.id}
    min = "DATE_FORMAT(min(published_at),'%Y-%m-%d')"
    max = "DATE_FORMAT(max(published_at),'%Y-%m-%d')"
        
    cond = ["published_at BETWEEN '#{start_date.beginning_of_month.to_s(:db)}' AND '#{myend_date.end_of_month.to_s(:db)}' "]
    sql = " DATE_FORMAT(max(published_at),'%Y-%m-%d') AS trend_date,"   
    sql += " CONCAT_WS(' - ',#{min},#{max}) AS period,"   
    sql += " 'month' AS trend_type,"      
    sql += "MONTH(published_at) AS month_number, "
    sql += select_account_name myaccounts
    sql += select_summary_sql
    
    records = YtChannel.select(sql).where(cond).
      where(["account_id in (?)",account_ids]).
      group("month_number")

    records
  end

  # select data for number of weeks
  # sum over week
  # ruby end_of_week is Sunday
  def get_select_trend_by_week start_date,myend_date, myaccounts
    
    if !myend_date.sunday?
     # myend_date = (myend_date-1.week).end_of_week
    end
    account_ids = myaccounts.map{|a| a.id}
    min = start_date.strftime "%Y-%m-%d"
    max = myend_date.strftime "%Y-%m-%d"
      
    User.logger.debug "    get_select_trend_by_week"
    cond = ["published_at BETWEEN '#{start_date.beginning_of_day.to_s(:db)}' AND '#{myend_date.end_of_day.to_s(:db)}' "]
    sql = " DATE_FORMAT(max(published_at),'%Y-%m-%d') AS trend_date,"     
    sql += " CONCAT_WS(' - ','#{min}','#{max}') AS period,"   
    sql += " 'week' AS trend_type,"   
     
    sql += "1 + DATEDIFF(published_at, '#{min}') DIV 7  AS week_number, "
    sql += "'#{min}' + INTERVAL (DATEDIFF(published_at, '#{min}') DIV 7) WEEK AS week_start_date,"

    sql += select_account_name myaccounts
    sql += select_summary_sql
    
    records = YtChannel.select(sql).where(cond).
      where(["account_id in (?)",account_ids]).
      group("week_number")
    records
  end
  
  # select data for number of days
  # sum over day
  def get_select_trend_by_day start_date,end_date, myaccounts
    User.logger.debug "    get_select_trend_by_day"
    account_ids = myaccounts.map{|a| a.id}
    cond = ["published_at BETWEEN '#{start_date.beginning_of_day.to_s(:db)}' AND '#{end_date.end_of_day.to_s(:db)}' "]
    sql = "DATE_FORMAT(published_at,'%Y-%m-%d') AS trend_date, "
    sql += " 'day' AS trend_type,"    
    sql += select_account_name myaccounts   
    sql += select_summary_sql
    records = YtChannel.select(sql).where(cond).
      where(["account_id in (?)",account_ids]).
      group("trend_date").order("trend_date").to_a
      
    records = fill_missing_rows records,start_date,end_date
    records

  end


  # start_date,end_date : Time object
  # myaccounts : array of Account object
  # return one active_record
  def get_select_lifetime start_date,end_date,myaccounts
    if start_date.strftime('%y%m%d') != end_date.strftime('%y%m%d')
      raise "start_date, end_date  must be on the same day. #{start_date} and #{end_date}"
    end
    account_ids = myaccounts.map{|a| a.id}
    cond = ["published_at BETWEEN '#{start_date.beginning_of_day.to_s(:db)}}' AND '#{end_date.end_of_day.to_s(:db)}}'"]
    sql = "DATE_FORMAT(published_at,'%Y-%m-%d') AS date, "
    sql += select_account_name myaccounts
    sql += "COALESCE(subscribers,0) AS total_subscribers,"
    sql += " COALESCE(comments,0) as total_comments, "
    sql += "COALESCE(views,0) as total_views, "
    sql += "COALESCE(videos,0) as total_videos, "
    sql += "(total_subscribers+total_comments+total_views) as total_number"
    records = YtChannel.select(sql).where(cond).where(["account_id in (?)",account_ids]).first
  end

  # start_date,end_date : Time object
  # myaccounts : array of Account object
  # return one active_record
  def get_select_by start_date,myend_date,myaccounts
    
    account_ids = myaccounts.map{|a| a.id}
    cond = ["published_at BETWEEN '#{start_date.beginning_of_day.to_s(:db)}' AND '#{myend_date.end_of_day.to_s(:db)}' "]
    sql = "'#{start_date.strftime('%Y-%m-%d')} - #{myend_date.strftime('%Y-%m-%d')}' AS period, "
    sql += select_account_name myaccounts
    sql += " 'placeholder' as changes,"
    sql += select_summary_sql
    record = YtChannel.select(sql).where(cond).where(["account_id in (?)",account_ids]).first
    record = filter_zero record
  end
  
  
  protected
  
  def filter_zero record
    if record.video_subscribers.to_i == 0 &&
      record.video_comments.to_i == 0 &&
      record.video_views.to_i == 0 &&
      record.video_likes.to_i == 0 &&
      record.video_favorites.to_i == 0
      nil
    else
      record
    end
  end
  
  def get_lifetime_result rec1, rec2
    results = []
    [rec1, rec2].each_with_index do |rec, i|
      result = init_struct
      total = rec.total_subscribers + rec.total_comments + 
         rec.total_views
      result.values = {:date=>rec.date,
          :subscribers=>rec.total_subscribers,
          :comments=>rec.total_comments,
          :views=>rec.total_views,
          :totals=>total
          }   
      results << result.values
    end
    results
  end

  def get_detail_result rec1, rec2
    compute_changes rec1,rec2
    if !rec1
      return missing_record rec2
    end
    results = []
    totals = []
    [rec1, rec2].each_with_index do |rec, i|
      result = init_struct
      result.values = {:period=>rec.period}
      result.values.merge! set_engagement_data(rec)
      totals << result.values[:totals]
      if i == 1
        rate = ((totals[1]-totals[0])*100/totals[0].to_f).round rescue 0 # 'N/A'
        rate = "#{rate} %" if rate!='N/A'
        
        result.values[:changes] = { 
            :subscribers=>@video_subscribers_change,
            :comments=>@video_comments_change,
            :favorites=>@video_favorites_change, 
            :likes=>@video_likes_change, 
            :views=>@video_views_change,
            :totals=>rate}         
        results << result.values
      end  
    end
    results
  end

  def get_period_result rec1, rec2
    results = []
    totals = []
    compute_changes rec1,rec2
    if !rec1
      return missing_record rec2
    end

    [rec1, rec2].each_with_index do |rec, i|
      result = init_struct
      result.values = {:period=>rec.period}
      result.values.merge! set_engagement_data(rec)
      totals << result.values[:totals]
      
      if i == 1
        rate = ((totals[1]-totals[0])*100/totals[0].to_f).round rescue 'N/A'
        rate = "#{rate} %" if rate!='N/A'
        
        result.values[:changes] = {:favorites=>@video_favorites_change, 
            :comments=>@video_comments_change,
            :likes=>@video_likes_change,
            :subscribers=>@video_subscribers_change, 
            :views=>@video_views_change,
            :totals=>rate}         
        results << result.values      
      end  
    end
    results
  end
 
  def filter_attributes rec_hash
    [:retweets,:mentions,:followers,:favorites].each do |key|
      rec_hash.delete(key)
    end
    rec_hash
  end
  
  def set_engagement_data rec
    begin
    if rec.video_subscribers==0
      subs = 'N/A'
    else
      subs = rec.video_subscribers
    end
    {:subscribers=> subs,
     :favorites=>rec.video_favorites,
     :likes=>rec.video_likes,
     :comments=>rec.video_comments,
     :views=>rec.video_views,
     :totals => (rec.video_favorites + rec.video_likes +
         rec.video_comments + rec.video_views + rec.video_subscribers.to_i)
    }
    rescue Exception=>ex
      Rails.logger.error "   set_engagement_data #{ex.message}"
      {}
    end
  end
  
  def select_summary_sql
    sql = "COALESCE(sum(video_subscribers),0) as video_subscribers," 
    sql += "COALESCE(sum(video_likes),0) as video_likes," 
    sql += "COALESCE(sum(video_comments),0) as video_comments,"
    sql += "COALESCE(sum(video_favorites),0) as video_favorites,"
    sql += " COALESCE(sum(video_views),0) as video_views"
    sql
  end
  
  def compute_changes rec1,rec2
    @video_likes_change = compute_change(rec2.video_likes,rec1.video_likes) rescue 'N/A'
    @video_comments_change = compute_change(rec2.video_comments,rec1.video_comments) rescue 'N/A'
    @video_favorites_change = compute_change(rec2.video_favorites,rec1.video_favorites) rescue 'N/A'
    @video_views_change = compute_change(rec2.video_views,rec1.video_views) rescue 'N/A'
    @video_subscribers_change = compute_change(rec2.video_subscribers,rec1.video_subscribers) rescue 'N/A'
    
  end    
   
  def fake_record date,trend_type
    max = parse_date date
    min = max - 6.days
    rec = OpenStruct.new
    rec.week_start_date = min
    rec.id = nil
    rec.trend_date = date
    rec.trend_type = trend_type
    rec.video_favorites = 0
    rec.video_comments = 0
    rec.video_likes = 0
    rec.video_views = 0
    rec.video_subscribers = 0
    rec.totals = 0
    rec
  end
 
  def missing_record rec
    results = []
    result = init_struct
    result.values = {:period=>rec.period}
    result.values.merge! set_engagement_data(rec)
    ch = 'N/A'
    result.values[:changes] = {:favorites=>ch, 
            :comments=>ch,
            :likes=>ch, 
            :views=>ch,
            :subscribers=>ch,
            :totals=>ch}         
    results << result.data
    msg = " #{applicatio_name} #{self.class.name} Data missing in #{rec.name} #{previous_period}"
    ErrorLog.to_error msg,msg,3
    results
  end
end

=begin
# start_date,end_date : Time object
  # myaccounts : array of Account object
  # return one active_record
  def get_subscribers_select_by start_date,myend_date,myaccounts
    account_ids = myaccounts.map{|a| a.id}
    range = "'#{start_date.beginning_of_day.to_s(:db)}' AND '#{myend_date.end_of_day.to_s(:db)}'"
    
    _min = "SELECT min(published_at) FROM yt_channels"
    _min += " WHERE published_at BETWEEN #{range} "
    _min += " AND account_id in (#{account_ids.join(',')})"
    _max = "SELECT max(published_at) FROM yt_channels"
    _max += " WHERE published_at BETWEEN #{range} "
    _max += " AND account_id in (#{account_ids.join(',')})"
    
    cond = [" published_at in (#{_min} UNION #{_max} )"]
    sql = "'#{start_date.strftime('%Y-%m-%d')} - #{myend_date.strftime('%Y-%m-%d')}' AS period, "
    sql += select_account_name myaccounts
    sql += " 'placeholder' as changes,"
    sql += " account_id,published_at,subscribers "
    records = YtChannel.select(sql).where(cond).
      where(["account_id in (?)",account_ids]).
      order('published_at').to_a
     
    diff = 0
    @max_subscribers = 0
    @min_subscribers = 0
    account_ids.each do | id |
      rows = records.select{|re| re.account_id == id }
      unless rows.empty?
        max = rows.max_by(&:published_at)
        max_all = rows.find_all{|i| i.published_at == max.published_at}
        max_sub = max_all.max_by do |ele|
          ele.subscribers.to_i
        end

        min = rows.min_by(&:published_at)
        min_all = rows.find_all{|i| i.published_at == min.published_at}
        min_sub = min_all.max_by do |ele|
          ele.subscribers.to_i
        end
        diff += max_sub.subscribers.to_i - min_sub.subscribers.to_i
        @max_subscribers += max_sub.subscribers.to_i
        @min_subscribers += min_sub.subscribers.to_i
      end
    end
    [@max_subscribers, @min_subscribers]
  end
  
  res = Net::HTTP.start('gdata.youtube.com', '80') do |http|
        req = Net::HTTP::Get.new("/feeds/api/videos/ylSA0zd1mfo")
        http.request(req)
       end
        
=end


