#
# this class is to get data from a facebook page
# first get top level likes, all posts
require Rails.root.to_s + '/lib/read_stat_detail'

class FbStatNew
    
  include ReadStatDetail
  
  SelectedColumns = ['replies_to_comment','total_likes','likes','shares', 'comments','posts']
  FbPageClass = FbPage
  # FbPageClass = Fbpage
  
  # all columns are life time data. So minus previous day's data
  # to get net new data for the day
  def process_records records, min, max
    # records=[1,3,3,4,5,6,7,8,10]
    records2=records[1..-1]
    results = []
    records2.each_with_index  do |record, i |
      # puts "  AAA #{i} #{record.nil?} record post_created_time = #{record.post_created_time}"
      SelectedColumns.each do | col |
        record.send "#{col}=", (record.send(col).to_i - records[i].send(col).to_i)
      end
      record.page_likes = record.total_likes
      results << record
    end
    results
  end
  def as_periods min, max
    sql = " CONCAT_WS(' - ',#{min.strftime('%Y-%m-%d')},#{max.strftime('%Y-%m-%d')}) AS period,"   
  end
  def get_select_trend_by_month start_date,myend_date, myaccounts
    if myend_date.day != myend_date.end_of_month.day
       myend_date = (myend_date - 1.month)
    end
    account_ids = myaccounts.map{|a| a.id}
    min = start_date.beginning_of_month.beginning_of_day - 1.day
    max = myend_date.end_of_month.end_of_day
    sql = " post_created_time AS trend_date,"   
    sql += as_periods(min, max)  
    sql += " 'month' AS trend_type,"      
    sql += "MONTH(post_created_time) AS month_number, "
    sql += select_summary_sql myaccounts
    records = FbPageClass.select(sql).
      where(["account_id in (?)",account_ids]).
      where(post_created_time: (min..max)).
      order("post_created_time")
    process_records records, min, max
  end
  def get_select_trend_by_week start_date,myend_date, myaccounts
    account_ids = myaccounts.map{|a| a.id}
    min = start_date.beginning_of_month.beginning_of_day - 1.day
    max = myend_date.end_of_month.end_of_day
    sql = " DATE_FORMAT(max(post_created_time),'%Y-%m-%d') AS trend_date,"     
    sql += as_periods(min, max)    
    sql += " 'week' AS trend_type,"   
    sql += "1 + DATEDIFF(post_created_time, '#{min}') DIV 7  AS week_number, "
    sql += "'#{min}' + INTERVAL (DATEDIFF(post_created_time, '#{min}') DIV 7) WEEK AS week_start_date,"
    sql += select_summary_sql myaccounts
    records = FbPageClass.select(sql).
      where(post_created_time: (min..max)).
      where(["account_id in (?)",account_ids]).
      group("week_number-1")

    process_records records, min, max
  end
  def get_select_trend_by_day start_date,end_date, myaccounts
    min = start_date.beginning_of_month.beginning_of_day - 1.day
    max = end_date.end_of_month.end_of_day
    account_ids = myaccounts.map{|a| a.id}
    sql = "DATE_FORMAT(post_created_time,'%Y-%m-%d') AS trend_date, "
    sql += " 'dai' AS trend_type,"    
    sql += select_summary_sql myaccounts
    records = FbPageClass.select(sql).
      where(post_created_time: (min..max)).
      where(["account_id in (?)",account_ids]).
      group("trend_date").to_a
    records = fill_missing_rows records, start_date,end_date
    process_records records, min, max
  end

  # start_date,end_date : Time object
  # myaccounts : array of Account object
  # return one active_record
  def get_select_by start_date, end_date, myaccounts
    min = start_date.beginning_of_month.beginning_of_day - 1.day
    max = end_date.end_of_month.end_of_day
    account_ids = myaccounts.map{|a| a.id}
    cond = ["post_created_time BETWEEN '#{start_date.beginning_of_day.to_s(:db)}' AND '#{end_date.end_of_day.to_s(:db)}' "]
    sql = "'#{start_date.strftime('%Y-%m-%d')} - #{end_date.strftime('%Y-%m-%d')}' AS period, "
    sql += select_summary_sql myaccounts
    record = FbPageClass.select(sql).
      where(post_created_time: (min..max)).
      where(["account_id in (?)",account_ids]).first
    record = filter_zero record
  end

  protected

  def get_lifetime_result rec1, rec2
    results = []
    [rec1, rec2].each_with_index do |rec, i|
      result = init_struct
      total = (rec.total_likes + rec.total_shares + rec.total_talking_about )
      result.values = {:date=>rec.date,
          :total_likes=>rec.total_likes,
          :total_shares=>rec.total_shares,
          :total_talking_about=>rec.total_talking_about,
          :totals=>total
          }
      results << result.values
    end
    results
  end
  
  
  def get_detail_result rec1, rec2
    pagelikes = calculate_pagelikes rec1, rec2
    compute_changes rec1, rec2   
    @page_likes_change = compute_change(pagelikes[1],pagelikes[0])
    if !rec1
      return missing_record rec2
    end
    
    results = []
    totals = []

    [rec1, rec2].each_with_index do |rec, i|
      next if !rec
      result = init_struct
      total = (pagelikes[i] + rec.likes + rec.shares + @comments[i])
      totals << total
      result.data = {:period=>rec.period,
          :story_likes=>rec.likes,
          :page_likes=>rec.page_likes,
          :shares=>rec.shares,
          :comments=>@comments[i],
          :totals=>total
          }
      if i == 1
        rate = ((totals[1]-totals[0])*100/totals[0].to_f).round rescue 0 # 'N/A'
        rate = "#{rate} %" if rate!='N/A'
        result.data[:changes] = {:page_likes=>@page_likes_change,
          :story_likes=>@likes_change,:shares=>@shares_change,
          :comments=>@comments_change,
          :totals=>rate}
        results << result.data
      end 
    end
    results
  end
  
  def get_period_result rec1, rec2
    results = []
    totals = []

    pagelikes = calculate_pagelikes rec1, rec2
    compute_changes rec1, rec2
    @page_likes_change = compute_change(pagelikes[1],pagelikes[0])
    
    if !rec2
      return nil
    elsif !rec1
      return missing_record rec2
    end
    [rec1, rec2].each_with_index do |rec, i|
      result = init_struct
      total = (pagelikes[i] + rec.likes + rec.shares + @comments[i])
      totals << total
      result.values = {:period=>rec.period,
          :story_likes=>rec.likes,
          :page_likes=>rec.page_likes,
          :shares=>rec.shares,
          :comments=>@comments[i],
          :totals=>total
          }
          
      if (i == 1)
        rate = ((totals[1]-totals[0])*100/totals[0].to_f).round rescue 'N/A'
        rate = "#{rate} %" if rate!='N/A'
        result.values[:changes]={:page_likes=>@page_likes_change,
           :story_likes=>@likes_change,:shares=>@shares_change,
           :comments=>@comments_change,
           :totals=>rate}
        results << result.values 
      end
    end
    results
  end

  def set_engagement_data rec
    comments=rec.comments + rec.replies_to_comment
    {:story_likes=>rec.likes,
     :page_likes => rec.page_likes,
     :shares=>rec.shares,
     :comments=>comments,
     :totals => (rec.page_likes+ rec.likes+ rec.shares+ comments)
   }
  end

  # total_likes into net new page likes after
  # process_records
  def calculate_pagelikes rec1, rec2
    likes1 = rec1.page_likes rescue 0
    likes2 = rec2.page_likes rescue 0
    @pagelikes = [likes1,likes2]
  end
  
  def select_summary_sql myaccounts
    sql = "post_created_time, " 
    sql += select_account_name myaccounts
    sql += " 0 AS page_likes, "   
    SelectedColumns.each do |col|
      sql += "COALESCE(#{col},0) as #{col},"
    end
    sql.chop
  end
  
  def compute_changes rec1, rec2
    if !rec1
      @comments_change=(rec2.replies_to_comment + rec2.comments)
      @likes_change=rec2.likes
      @shares_change=rec2.shares
      @page_likes_change=rec2.page_likes
      @comments = [0,(rec2.replies_to_comment + rec2.comments)]
    elsif !rec2
      @comments_change= -1*(rec1.replies_to_comment + rec1.comments)
      @likes_change= -1*rec1.likes
      @shares_change= -1*rec1.shares
      @page_likes_change= -1*rec1.page_likes
      @comments = [(rec1.replies_to_comment + rec1.comments),0]
    else
      @comments = [(rec1.replies_to_comment + rec1.comments),
                (rec2.replies_to_comment + rec2.comments)]
      @comments_change = compute_change(@comments[1],@comments[0]) 
      @likes_change = compute_change(rec2.likes,rec1.likes)
      @shares_change = compute_change(rec2.shares,rec1.shares)
      # @fan_adds_change 
      @page_likes_change = compute_change(rec2.page_likes,rec1.page_likes)
    end
  end
  
  def filter_zero record
    if record.replies_to_comment == 0 &&
       record.page_likes == 0 &&
       record.likes == 0 &&
       record.shares == 0 &&
       record.comments == 0
       nil
    else
      record
    end
  end
  
  def filter_attributes rec_hash
    [:story_likes,:shares,:replies_to_comment,:comments,:page_likes].each do |key|
      rec_hash.delete(key)
    end
    rec_hash
  end
  
  def fake_record date,trend_type
    max = parse_date date
    min = max - 6.days
    rec = OpenStruct.new
    rec.week_start_date = min
    rec.id = nil
    rec.trend_date = date
    rec.trend_type = trend_type
    rec.likes = 0
    rec.shares = 0
    rec.replies_to_comment = 0
    rec.comments = 0
    rec.page_likes = 0
    rec
  end
  
  def missing_record rec
    results = []
    result = init_struct
    idx = 1
    total = (@pagelikes[idx] + rec.likes + rec.shares + @comments[idx])
    result.data = {:period=>rec.period,
          :story_likes=>rec.likes,
          :page_likes=>rec.page_likes,
          :shares=>rec.shares,
          :comments=>@comments[idx],
          :totals=>total
          }
    ch = 'N/A'
    result.data[:changes] = {:page_likes=>ch,
          :story_likes=>ch,
          :shares=>ch,
          :comments=>ch,
          :totals=>ch}
    results << result.data
    msg = "#{self.class.name} Data missing in #{rec.name} #{previous_period}"
    ErrorLog.logger.error msg
    ErrorLog.to_error msg,msg,3
    results
  end
end
