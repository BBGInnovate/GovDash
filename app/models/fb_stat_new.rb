#
# this class is to get data from a facebook page
# first get top level likes, all posts
require Rails.root.to_s + '/lib/read_stat_detail'

class FbStatNew
    
  include ReadStatDetail
  
  SelectedColumns = ['replies_to_comment','total_likes','likes','shares', 'comments','posts','fan_adds_day']
  # FbPageClass = FbPage  # this table stores posts net new data per account per day
  # except total_* columns which for life time data
  FbPageClass = Fbpage  # this table stores life time data per account per day
  
  # get net increase between two date endpoints
  # records is in post_created_time asc order
  # return one record
  def get_net_increase records, min, max
    puts "  #{Time.now.to_s(:db)}  get_net_increase"
    if records.empty?
      rec = OpenStruct.new
      rec.week_start_date = min
      rec.id = nil
      ## rec.period = "#{min.strftime('%Y-%m-%d')} - #{max.strftime('%Y-%m-%d')}"
      rec.trend_date = min.to_s
      rec.trend_type = "trend_type"
      rec.likes = 0
      rec.shares = 0
      rec.replies_to_comment = 0
      rec.comments = 0
      rec.total_likes = 0
      rec.page_likes = 0
      return rec
    end
    # records is in post_created_time order
    rec1 = nil
    total_likes = 0
    records.each do |rec|
       if rec.class != OpenStruct
         if rec.total_likes != 0
           if total_likes == 0
             total_likes = rec.total_likes
           end
         end
         if rec.likes != 0
           # get the first real likes record
           rec1 = rec
           break
         end
       end
    end
    # if no real likes data in this period
    if !rec1
      rec1 = records.first
      puts "   GET_net_increase: no good data in #{min.strftime('%Y-%m-%d')} - #{max.strftime('%Y-%m-%d')}"
    end
    rec2 = records.last
    total_likes = rec2.total_likes - total_likes
    # get net increase between two date endpoints
    SelectedColumns.each do | col |
      rec2.send "#{col}=", (rec2.send(col).to_i - rec1.send(col).to_i)
    end
    # from now on, rec2 is the net increase of 
    # records.last and records.first 
    rec2.total_likes = total_likes
    rec2.page_likes = total_likes
    rec2.fan_adds_day = total_likes
    rec2
  end
  
  def sum_rows rows
    if FbPageClass == FbPage
      return rows
    end
    result = Marshal.load( Marshal.dump(rows.last) )
    hsh = {}
    SelectedColumns.each do | col |
      hsh[col] = 0
      rows.each do |row|
        hsh[col] += row.send(col).to_i
	   end
	   result.send "#{col}=", hsh[col]
    end
    result.page_likes = result.total_likes
    result
  end
  
  #
  # INPUT: records is array, each row has one day's life time data
  # records.first contains min - 1.day data. If min - 1.day data is
  # not available, records.first is a fake data
  # all columns are life time data. So minus previous day's data
  # to get net new data for the day
  # OUTPUT: array each row has one day's net new data
  def process_records records, min, max
    if FbPageClass == FbPage
      records.each do |rec|
        rec.page_likes = rec.total_likes
      end
      return records
    end
    # records include missing date
    results = []
    records.each do | rec |
      results << Marshal.load( Marshal.dump(rec) )
    end
    
    records.each_with_index do |record, i|
      break if i == (records.size-1)
      # Rails.logger.debug "  #{results[i+1].post_created_time} #{results[i+1].likes}"
      SelectedColumns.each do | col |
        results[i+1].send "#{col}=", (records[i+1].send(col).to_i - record.send(col).to_i)
      end
      #puts "   BBBB #{results[i+1].trend_date} #{results[i+1].likes}"
      results[i+1].page_likes = results[i+1].total_likes
      results[i+1].fan_adds_day = results[i+1].total_likes
    end
    results.shift
    results
  end
  def as_periods min, max
    sql = " CONCAT_WS(' - ','#{min.strftime('%Y-%m-%d')}','#{max.strftime('%Y-%m-%d')}') AS period,"   
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
      where(post_created_time: (min..max)).to_a

    process_records records, min, max
  end
  def get_select_trend_by_week start_date,myend_date, myaccounts
    # puts "    AAAA calling #get_select_trend_by_week}"
    account_ids = myaccounts.map{|a| a.id}
    min = start_date.beginning_of_month.beginning_of_day
    max = myend_date.end_of_month.end_of_day
    cur_min_date = min - 1.day
    records = []
    while cur_min_date < max+1.day
      cur_max_date = cur_min_date + 7.days
      sql = " DATE_FORMAT(post_created_time,'%Y-%m-%d') AS trend_date,"     
      sql += as_periods(cur_min_date, cur_max_date)    
      sql += " 'week' AS trend_type,"   
      sql += "1 + DATEDIFF(post_created_time, '#{min}') DIV 7  AS week_number, "
      sql += "'#{cur_min_date}' + INTERVAL (DATEDIFF(post_created_time, '#{cur_min_date}') DIV 7) WEEK AS week_start_date,"
      sql += select_summary_sql myaccounts
      rows = FbPageClass.select(sql).
        where(post_created_time: (cur_min_date..cur_max_date)).
        where(["account_id in (?)",account_ids]).to_a
        # group("week_number-1").to_a

      unless rows.empty?
        results = process_records(rows, cur_min_date, cur_max_date)
        records << sum_rows(results)
      end  
      cur_min_date = cur_max_date + 1.day
    end
    records.flatten!
    # records.each do |rc|
    #  puts "  #{rc.post_created_time} #{rc.period} #{rc.likes} #{rc.total_likes}"
    # end
    records
    
  end
  
  # return N rows, where N = (end_date-start_date+1) days
  # each row for one day
  def get_select_trend_by_day start_date,end_date, myaccounts
    Rails.logger.debug "   AAA get_select_trend_by_day #{start_date},#{end_date}"
    # Rails.logger.debug ""
    if FbPageClass == Fbpage
      min = start_date.beginning_of_day - 1.day
    else
      min = start_date.beginning_of_day
    end
    max = end_date.end_of_day
    account_ids = myaccounts.map{|a| a.id}
    sql = "DATE_FORMAT(post_created_time,'%Y-%m-%d') AS trend_date, "
    sql += " 'dai' AS trend_type,"    
    sql += select_summary_sql myaccounts
    records = FbPageClass.select(sql).
      where(post_created_time: (min..max)).
      where(["account_id in (?)",account_ids]).
      group("trend_date").to_a
    records = fill_missing_rows records, min,max
    process_records records, min, max
  end

  # start_date,end_date : Time object
  # myaccounts : array of Account object
  # return one active_record
  def get_select_by start_date, end_date, myaccounts
    Rails.logger.debug "  AAA  Calling get_select_by"
    # Rails.logger.debug ""
    min = start_date.beginning_of_day - 1.day
    max = end_date.end_of_day
    account_ids = myaccounts.map{|a| a.id}
    cond = ["post_created_time BETWEEN '#{start_date.beginning_of_day.to_s(:db)}' AND '#{end_date.end_of_day.to_s(:db)}' "]
    sql = as_periods(min, max)
    sql += " post_created_time AS trend_date," 
    sql += select_summary_sql myaccounts
    records = FbPageClass.select(sql).
      where(post_created_time: (min..max)).
      where(["account_id in (?)",account_ids]).
      order("post_created_time").to_a
    if FbPageClass == FbPage
      record = records.first
      t_likes = FbPageClass.select("total_likes").Fbpage.copy_from_fb_pages
         where('total_likes is not null').
         where(post_created_time: (min..max)).
         where(["account_id in (?)",account_ids]).
         order('post_created_time').to_a
      # record.total_likes = record.fan_adds_day
      record.total_likes = t_likes.last.total_likes - t_likes.first.total_likes
      record.page_likes = record.total_likes
      filter_zero record
    else
      # don't fil missing date
      # records = fill_missing_rows records, min,max
      get_net_increase records, min, max
    end
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
      # in "trend"
      result.data = {:period=>rec.period,
          :story_likes=>rec.likes,
          :page_likes=>rec.total_likes,
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
  #
  # "values": {"period": [
  def get_period_result rec1, rec2
    results = []
    totals = []

    # puts "       PPP #{rec1}, #{rec2}"
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
      ## "values": {"period": [
      result.values = {:period=>rec.period,
          :story_likes=>rec.likes,
          :page_likes=>rec.total_likes,
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
    likes1 = rec1.total_likes rescue 0
    likes2 = rec2.total_likes rescue 0
    @pagelikes = [likes1,likes2]
  end
  
  def select_summary_sql myaccounts
    sql = "post_created_time, " 
    sql += select_account_name myaccounts
    sql += " 0 AS page_likes, "   
    SelectedColumns.each do |col|
      if FbPageClass == FbPage
        sel = "sum(#{col})"
      else
        sel = col
      end
      sql += "COALESCE(#{sel},0) as #{col},"
    end
    sql.chop
  end
  
  def compute_changes rec1, rec2
    if !rec1
      @comments_change=(rec2.replies_to_comment + rec2.comments)
      @likes_change=rec2.likes
      @shares_change=rec2.shares
      @page_likes_change=rec2.total_likes
      @comments = [0,(rec2.replies_to_comment + rec2.comments)]
    elsif !rec2
      @comments_change= -1*(rec1.replies_to_comment + rec1.comments)
      @likes_change= -1*rec1.likes
      @shares_change= -1*rec1.shares
      @page_likes_change= -1*rec1.total_likes
      @comments = [(rec1.replies_to_comment + rec1.comments),0]
    else
      @comments = [(rec1.replies_to_comment + rec1.comments),
                (rec2.replies_to_comment + rec2.comments)]
      @comments_change = compute_change(@comments[1],@comments[0]) 
      @likes_change = compute_change(rec2.likes,rec1.likes)
      @shares_change = compute_change(rec2.shares,rec1.shares)
      # @fan_adds_change
      @page_likes_change = compute_change(rec2.total_likes,rec1.total_likes)
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
  
  # this applies only to the period == 1.week
  def fake_record date,trend_type
    max = parse_date date
    min = max - 6.days
    rec = OpenStruct.new
    rec.period = "#{min.strftime('%Y-%m-%d')} - #{max.strftime('%Y-%m-%d')}"
    rec.week_start_date = min
    rec.id = nil
    rec.trend_date = date
    rec.trend_type = trend_type
    rec.likes = 0
    rec.shares = 0
    rec.replies_to_comment = 0
    rec.comments = 0
    rec.page_likes = 0
    rec.total_likes = 0
    rec.post_created_time = max
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
    msg = " #{application_name} #{self.class.name} Data missing in #{rec.name} #{previous_period}"
    ErrorLog.logger.error msg
    ErrorLog.to_error msg,msg,3
    results
  end
end
