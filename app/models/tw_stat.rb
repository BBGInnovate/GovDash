require Rails.root.to_s + '/lib/read_stat_detail'

class TwStat
  include ReadStatDetail

  # select data for one year
  # sum over month
  def get_select_trend_by_month start_date,myend_date, myaccounts
    if myend_date.day != myend_date.end_of_month.day
       myend_date = (myend_date - 1.month)
    end
    account_ids = myaccounts.map{|a| a.id}
    min = "DATE_FORMAT(min(tweet_created_at),'%Y-%m-%d')"
    max = "DATE_FORMAT(max(tweet_created_at),'%Y-%m-%d')"
        
    cond = ["tweet_created_at BETWEEN '#{start_date.beginning_of_month.to_s(:db)}' AND '#{myend_date.end_of_month.to_s(:db)}' "]
    sql = " DATE_FORMAT(max(tweet_created_at),'%Y-%m-%d') AS trend_date,"   
    sql += " CONCAT_WS(' - ',#{min},#{max}) AS period,"   
    sql += " 'month' AS trend_type,"      
    sql += "MONTH(tweet_created_at) AS month_number, "
    sql += select_account_name myaccounts
    sql += select_summary_sql
    
    records = TwTimeline.select(sql).where(cond).
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
    cond = ["tweet_created_at BETWEEN '#{start_date.beginning_of_day.to_s(:db)}' AND '#{myend_date.end_of_day.to_s(:db)}' "]
    sql = " DATE_FORMAT(max(tweet_created_at),'%Y-%m-%d') AS trend_date,"     
    sql += " CONCAT_WS(' - ','#{min}','#{max}') AS period,"   
    sql += " 'week' AS trend_type,"   
     
    sql += "1 + DATEDIFF(tweet_created_at, '#{min}') DIV 7  AS week_number, "
    sql += "'#{min}' + INTERVAL (DATEDIFF(tweet_created_at, '#{min}') DIV 7) WEEK AS week_start_date,"

    sql += select_account_name myaccounts
    sql += select_summary_sql
    
    records = TwTimeline.select(sql).where(cond).
      where(["account_id in (?)",account_ids]).
      group("week_number")
    records
  end
  
  # select data for number of days
  # sum over day
  def get_select_trend_by_day start_date,end_date, myaccounts
    User.logger.debug "    get_select_trend_by_day"
    account_ids = myaccounts.map{|a| a.id}
    cond = ["tweet_created_at BETWEEN '#{start_date.beginning_of_day.to_s(:db)}' AND '#{end_date.end_of_day.to_s(:db)}' "]
    sql = "DATE_FORMAT(tweet_created_at,'%Y-%m-%d') AS trend_date, "
    sql += " 'day' AS trend_type,"    
    sql += select_account_name myaccounts   
    sql += select_summary_sql
    records = TwTimeline.select(sql).where(cond).
      where(["account_id in (?)",account_ids]).
      group("trend_date").to_a
      
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
    cond = ["tweet_created_at BETWEEN '#{start_date.beginning_of_day.to_s(:db)}}' AND '#{end_date.end_of_day.to_s(:db)}}'"]
    sql = "DATE_FORMAT(tweet_created_at,'%Y-%m-%d') AS date, "
    sql += select_account_name myaccounts
    sql += "COALESCE(sum(total_tweets),0) AS total_tweets,"
    sql += " COALESCE(sum(total_favorites),0) as total_favorites, "
    sql += "COALESCE(sum(total_followers),0) as total_followers, "
    sql += "COALESCE(sum(total_tweets+total_favorites+total_followers),0) as total_number"
    records = TwTimeline.select(sql).where(cond).where(["account_id in (?)",account_ids]).first
  end

  # start_date,end_date : Time object
  # myaccounts : array of Account object
  # return one active_record
  def get_select_by start_date,myend_date,myaccounts
    account_ids = myaccounts.map{|a| a.id}
    cond = ["tweet_created_at BETWEEN '#{start_date.beginning_of_day.to_s(:db)}' AND '#{myend_date.end_of_day.to_s(:db)}' "]
    sql = "'#{start_date.strftime('%Y-%m-%d')} - #{myend_date.strftime('%Y-%m-%d')}' AS period, "
    sql += select_account_name myaccounts
    sql += " 'placeholder' as changes,"
    sql += select_summary_sql
    record = TwTimeline.select(sql).where(cond).where(["account_id in (?)",account_ids]).first
    record = filter_zero record
  end
  
  protected
  
  def filter_zero record
    if record.tweets == 0 &&
      record.favorites == 0 &&
      record.followers == 0 &&
      record.retweets == 0 &&
      record.mentions == 0
      nil
    else
      record
    end
  end
  
  def get_lifetime_result rec1, rec2
    results = []
    [rec1, rec2].each_with_index do |rec, i|
      result = init_struct
      total = rec.total_tweets + rec.total_followers + rec.total_followers
      result.values = {:date=>rec.date,
          :total_tweets=>rec.total_tweets,
          :total_favorites=>rec.total_favorites,
          :total_followers=>rec.total_followers,
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
        
        result.values[:changes] = {:retweets=>@retweets_change, 
            :mentions=>@mentions_change,
            :favorites=>@favorites_change, 
            :followers=>@followers_change,
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
        
        result.values[:changes] = {:retweets=>@retweets_change, 
            :mentions=>@mentions_change,
            :favorites=>@favorites_change, 
            :followers=>@followers_change,
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
    {
     :retweets=>rec.retweets,
     :mentions=>rec.mentions,
     :followers=>rec.followers,
     :favorites=>rec.favorites,
     :totals => (rec.retweets + rec.mentions +
         rec.followers + rec.favorites)
    }
    rescue
      {}
    end
  end
  
  def select_summary_sql
    sql = "COALESCE(sum(tweets),0) as tweets," 
    sql += "COALESCE(sum(retweets),0) as retweets,"
    sql += "COALESCE(sum(mentions),0) as mentions,"
    sql += " COALESCE( sum(favorites),0) as favorites, COALESCE(sum(followers),0) as followers"
    sql
  end
  
  def compute_changes rec1,rec2
    @retweets_change = compute_change(rec2.retweets,rec1.retweets) rescue 'N/A'
    @mentions_change = compute_change(rec2.mentions,rec1.mentions) rescue 'N/A'
    @favorites_change = compute_change(rec2.favorites,rec1.favorites) rescue 'N/A'
    @followers_change = compute_change(rec2.followers,rec1.followers) rescue 'N/A'
  end    
   
  def fake_record date,trend_type
    max = parse_date date
    min = max - 6.days
    rec = OpenStruct.new
    rec.week_start_date = min
    rec.id = nil
    rec.trend_date = date
    rec.trend_type = trend_type
    rec.tweets = 0
    rec.retweets = 0
    rec.mentions = 0
    rec.favorites = 0
    rec.followers = 0
    rec.totals = 0
    rec
  end
 
  def missing_record rec
    results = []
    result = init_struct
    result.values = {:period=>rec.period}
    result.values.merge! set_engagement_data(rec)
    ch = 'N/A'
    result.values[:changes] = {:retweets=>ch, 
            :mentions=>ch,
            :favorites=>ch, 
            :followers=>ch,
            :totals=>ch}         
    results << result.data
    msg = "#{self.class.name} Data missing in #{rec.name} #{previous_period}"
    ErrorLog.to_error msg,msg,3
    results
  end
end
