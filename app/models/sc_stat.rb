require Rails.root.to_s + '/lib/read_stat_detail'

class ScStat
  include ReadStatDetail

  # select data for one year
  # sum over month
  def get_select_trend_by_month start_date,myend_date, myaccounts
    if myend_date.day != myend_date.end_of_month.day
       myend_date = (myend_date - 1.month)
    end
    account_ids = myaccounts.map{|a| a.id}
    segment_ids = sc_segment_ids(account_ids)
    min = "DATE_FORMAT(min(created_at),'%Y-%m-%d')"
    max = "DATE_FORMAT(max(created_at),'%Y-%m-%d')"
        
    cond = ["created_at BETWEEN '#{start_date.beginning_of_month.to_s(:db)}' AND '#{myend_date.end_of_month.to_s(:db)}' "]
    sql = " DATE_FORMAT(max(created_at),'%Y-%m-%d') AS trend_date,"   
    sql += " CONCAT_WS(' - ',#{min},#{max}) AS period,"   
    sql += " 'month' AS trend_type,"      
    sql += "MONTH(created_at) AS month_number, "
    sql += select_account_name myaccounts
    sql += select_summary_sql
    
    records = ScReferralTraffic.select(sql).where(cond).
      where(["sc_segment_id in (?)", segment_ids]).
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
    segment_ids = sc_segment_ids(account_ids)
    min = start_date.strftime "%Y-%m-%d"
    max = myend_date.strftime "%Y-%m-%d"
      
    cond = ["created_at BETWEEN '#{start_date.beginning_of_day.to_s(:db)}' AND '#{myend_date.end_of_day.to_s(:db)}' "]
    sql = " DATE_FORMAT(max(created_at),'%Y-%m-%d') AS trend_date,"     
    sql += " CONCAT_WS(' - ','#{min}','#{max}') AS period,"   
    sql += " 'week' AS trend_type,"   
    sql += "1 + DATEDIFF(created_at, '#{min}') DIV 7  AS week_number, "
    sql += "'#{min}' + INTERVAL (DATEDIFF(created_at, '#{min}') DIV 7) WEEK AS week_start_date,"
    sql += select_account_name myaccounts
    sql += select_summary_sql
    
    records = ScReferralTraffic.select(sql).where(cond).
      where(["segment_id in (?)", segment_ids]).
      group("week_number")
    records
  end
  
  # select data for number of days
  # sum over day
  def get_select_trend_by_day start_date,end_date, myaccounts
    account_ids = myaccounts.map{|a| a.id}
    segment_ids = sc_segment_ids(account_ids)
    if segment_ids.empty?
      records = []
      records = fill_missing_rows records,start_date,end_date
      return records
    end
    cond = ["created_at BETWEEN '#{start_date.beginning_of_day.to_s(:db)}' AND '#{end_date.end_of_day.to_s(:db)}' "]
    sql = "DATE_FORMAT(created_at,'%Y-%m-%d') AS trend_date, "
    sql += " 'day' AS trend_type,"    
    sql += select_account_name myaccounts   
    sql += select_summary_sql
    records = ScReferralTraffic.select(sql).where(cond).
      where(["sc_segment_id in (?)",segment_ids ]).
      group("trend_date").to_a
    
    records = fill_missing_rows records,start_date,end_date
    records
  end

  # start_date,end_date : Time object
  # myaccounts : array of Account object
  # return one active_record
  def get_select_by start_date,myend_date,myaccounts=[]
    account_ids = myaccounts.map{|a| a.id}
    segment_ids = sc_segment_ids(account_ids)
    if segment_ids.empty?
      nil
    else
      cond = ["created_at BETWEEN '#{start_date.beginning_of_day.to_s(:db)}' AND '#{myend_date.end_of_day.to_s(:db)}' "]
      sql = "'#{start_date.strftime('%Y-%m-%d')} - #{myend_date.strftime('%Y-%m-%d')}' AS period, "
      sql += select_account_name myaccounts
      sql += " 'placeholder' as changes,"
      sql += select_summary_sql
      record = ScReferralTraffic.select(sql).where(cond).where(["sc_segment_id in (?)",segment_ids]).first
      record = filter_zero record
    end
  end
  
  protected

  def filter_zero record
    if record.facebook_count == 0 &&
      record.twitter_count == 0
      nil
    else
      record
    end
  end
  def sc_segment_ids account_ids
    # account_ids = [1,4,21,25,5]
    records = AccountsScSegment.where(["account_id in (?)", account_ids])
    segment_ids = records.map{|rec| rec.sc_segment_id}.uniq
  end
  
  def get_detail_result rec1, rec2
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
        rate = ((totals[1]-totals[0])*100/totals[0].to_f).round rescue 0 # 'N/A'
        rate = "#{rate} %" if rate!='N/A'
        
        result.values[:changes] = {:facebook=>@facebook_change, 
            :twitter=>@twitter_change,
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
        
        result.values[:changes] = {:facebook=>@facebook_change, 
            :twitter=>@twitter_change,
            :totals=>rate}         
        results << result.values      
      end  
      
    end
    results
  end
 
  def filter_attributes rec_hash
    # arr = [:facebook_count,:twitter_count]
    arr = []
    arr.each do |key|
      rec_hash.delete(key)
    end
    rec_hash
  end
  
  def set_engagement_data rec
    begin
    {
     :twitter_count=>rec.twitter_count,
     :facebook_count=>rec.facebook_count,
     :totals => (rec.twitter_count + rec.facebook_count)
    }
    rescue
      {}
    end
  end
  
  def select_summary_sql
    sql = "COALESCE(sum(twitter_count),0) as twitter_count," 
    sql += "COALESCE(sum(facebook_count),0) as facebook_count "
    sql
  end
  
  def compute_changes rec1,rec2
    @facebook_change = 0
    @twitter_change = 0
    if rec1 && rec2
      @facebook_change = compute_change(rec2.facebook_count,rec1.facebook_count)
      @twitter_change = compute_change(rec2.twitter_count,rec1.twitter_count)
    elsif rec2
      @facebook_change = 'N/A' 
      @twitter_change = 'N/A' 
    end    
  end
   
  def fake_record date,trend_type
    max = parse_date date
    min = max - 6.days
    rec = OpenStruct.new
    rec.week_start_date = min
    rec.id = nil
    rec.trend_date = date
    rec.trend_type = trend_type
    rec.facebook_count = 0
    rec.twitter_count = 0
    rec.totals = 0
    rec
  end
 
  def missing_record rec
    results = []
    result = init_struct
    result.values = {:period=>rec.period}
    result.values.merge! set_engagement_data(rec)
    ch = 'N/A'
    result.values[:changes] = {:facebook=>ch, 
            :twitter=>ch,
            :totals=>ch}         
    results << result.data
    msg = "#{self.class.name} Data missing in #{rec.name} #{previous_period}"
    ErrorLog.to_error msg,msg,3   

    results
  end
end
