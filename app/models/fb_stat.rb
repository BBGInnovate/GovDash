#
# this class is to get data from a facebook page
# first get top level likes, all posts
require Rails.root.to_s + '/lib/read_stat_detail'

class FbStat
    
  include ReadStatDetail
  
  # select data for one year
  # sum over month
  def get_select_trend_by_month start_date,myend_date, myaccounts
    if myend_date.day != myend_date.end_of_month.day
       myend_date = (myend_date - 1.month)
    end
    account_ids = myaccounts.map{|a| a.id}
    # min = start_date.strftime "%Y-%m-%d"
    # max = myend_date.strftime "%Y-%m-%d"
    min = "DATE_FORMAT(min(post_created_time),'%Y-%m-%d')"
    max = "DATE_FORMAT(max(post_created_time),'%Y-%m-%d')"
    cond = ["post_created_time BETWEEN '#{start_date.beginning_of_month.to_s(:db)}' AND '#{myend_date.end_of_month.to_s(:db)}' "]
    sql = " DATE_FORMAT(max(post_created_time),'%Y-%m-%d') AS trend_date,"   
    sql += " CONCAT_WS(' - ',#{min},#{max}) AS period,"   
    sql += " 'month' AS trend_type,"      
    sql += "MONTH(post_created_time) AS month_number, "
    sql += select_account_name myaccounts
    sql += " 0 AS page_likes, "   
    sql += select_summary_sql
    
    records = FbPage.select(sql).where(cond).
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
    
    cond = ["post_created_time BETWEEN '#{start_date.beginning_of_day.to_s(:db)}' AND '#{myend_date.end_of_day.to_s(:db)}' "]
    sql = " DATE_FORMAT(max(post_created_time),'%Y-%m-%d') AS trend_date,"     
    sql += " CONCAT_WS(' - ','#{min}','#{max}') AS period,"   
    sql += " 'week' AS trend_type,"   
    
    sql += "1 + DATEDIFF(post_created_time, '#{min}') DIV 7  AS week_number, "
    sql += "'#{min}' + INTERVAL (DATEDIFF(post_created_time, '#{min}') DIV 7) WEEK AS week_start_date,"
    # sql += "WEEK(post_created_time,1) AS week_number, "
    sql += select_account_name myaccounts
    sql += " 0 AS page_likes, "   
    sql += select_summary_sql
    records = FbPage.select(sql).where(cond).
      where(["account_id in (?)",account_ids]).
      group("week_number-1")

    records
  end
  
  # select data for number of days
  # sum over day
  def get_select_trend_by_day start_date,end_date, myaccounts
    account_ids = myaccounts.map{|a| a.id}
    cond = ["post_created_time BETWEEN '#{start_date.beginning_of_day.to_s(:db)}' AND '#{end_date.end_of_day.to_s(:db)}' "]
    sql = "DATE_FORMAT(post_created_time,'%Y-%m-%d') AS trend_date, "
    sql += " 'dai' AS trend_type,"    
    sql += select_account_name myaccounts
    sql += " 'placeholder' AS page_likes, "   
    sql += select_summary_sql
    # select_trend_page_likes(start_date,end_date,myaccounts, 1.day) # just populate  page_likes hash
    
    records = FbPage.select(sql).where(cond).
      where(["account_id in (?)",account_ids]).
      group("trend_date").to_a
    records = fill_missing_rows records, start_date,end_date
    records
  end
  
  # works for period == 1.day
  def select_trend_page_likes start_date,end_date,myaccounts,period=1.day
    from_date = start_date - period
    while from_date <= end_date.end_of_day
      rec = get_select_lifetime(from_date, from_date,myaccounts)
      from_date += period
      name = get_account_name myaccounts
      page_likes[name]["#{rec.date}"] = rec.total_likes
    end
 
  end
  
  # start_date,end_date : Time object
  # myaccounts : array of Account object
  # return one active_record
  def get_select_lifetime start_date,end_date,myaccounts
    if start_date.strftime('%y%m%d') != end_date.strftime('%y%m%d')
      raise "start_date, end_date  must be on the same day. #{start_date} and #{end_date}"
    end
  end

  # start_date,end_date : Time object
  # myaccounts : array of Account object
  # return one active_record
  def get_select_by start_date, end_date, myaccounts
    account_ids = myaccounts.map{|a| a.id}
    cond = ["post_created_time BETWEEN '#{start_date.beginning_of_day.to_s(:db)}' AND '#{end_date.end_of_day.to_s(:db)}' "]
    sql = "'#{start_date.strftime('%Y-%m-%d')} - #{end_date.strftime('%Y-%m-%d')}' AS period, "
    sql += select_account_name myaccounts
    sql += " 'placeholder' as changes,"
    sql += select_summary_sql
    record = FbPage.select(sql).where(cond).where(["account_id in (?)",account_ids]).first
    record = filter_zero record
  end
  
  # daily insight stats 
  # consumptions_day, story_adds_day, fan_adds_day
  def insight_by
    account_ids = options[:account_ids]
    records = []
    records << get_insight_by_period(period1_from_date, period1_end_date,account_ids)
    records << get_insight_by_period(period2_from_date, period2_end_date,account_ids)
    records.flatten!
    final_results << {:insights=>records}
  end
   
  # insight stats 
  # story_adds_by_story_type_day
  def story_adds_by_story_type_day
    logger.warn "DEPRECATED 'story_adds_by_story_type_day' use 'story_adds_by_story_type_period' instead"
    story_adds_by_story_type_period
  end
 
  def story_adds_by_story_type_period
    account_ids = options[:account_ids]
    records = []
    records << get_story_adds_by_story_type_period_by(period1_from_date, period1_end_date,account_ids)
    records << get_story_adds_by_story_type_period_by(period2_from_date, period2_end_date,account_ids)
    records.flatten!
    final_results << {:story_adds_by_story_type_period=>records}
  end
    
  # weekly insight stats 
  # page_stories_week
  def stories_week_by
    account_ids = options[:account_ids]
    records = []
    
     [[period1_from_date,period1_end_date],
      [period2_from_date,period2_end_date]].each do |period|   
        rec = get_stories_week_by(period[0],period[1],account_ids).first      
      if !rec
        records << [{'date'=>to_date.strftime('%Y-%m-%d'),'stories_week'=>0}]
      else
        attributes = rec.attributes
        # remove id from attr
        attributes.delete('id')
        records << attributes 
      end
    end
    records.flatten!
    final_results << {:stories_week=>records}
  end
  # insight stats 
  # stories_by_story_type_week
  def story_type_week_by
    account_ids = options[:account_ids] 
    records = []
    [current_from_date, end_date].each do |period|   
      records << get_story_type_week_by(period,period,account_ids)     
    end
    records.flatten!
    final_results << {:story_type_week=>records}
  end
  
  # insight stats 
  # 
  def consumption_type_day_by
    account_ids = options[:account_ids] 
    records = []  
    records << get_consumption_type_period_by(period1_from_date,period1_end_date,account_ids)
    records.flatten!    
    records << get_consumption_type_period_by(period2_from_date,period2_end_date,account_ids)
    records.flatten!
    final_results << {:consumption_type_day=>records}
  end
  
  # this likes is the same as in https://www.facebook.com/voiceofamerica
  def get_likes
    today = Time.zone.now
    if post_created_time > today.beginning_of_day &&
       post_created_time <= today.end_of_day
       link = "https://graph.facebook.com/?id=#{self.account.object_name}"
       response = fetch(link)
       json = JSON.parse response.body
       likes = json['likes']
       likes
    end
  end
  
  def save_lifetime_data
    today = Time.zone.now
    if post_created_time > today.beginning_of_day &&
       post_created_time <= today.end_of_day
       # link = "https://graph.facebook.com/?id=http://www.voanews.com"
       link = "https://graph.facebook.com/?id=#{self.object_name}"
       response = fetch(link)
       json = JSON.parse response.body
       websites = json['website'].split(' ')
       
       shares = 0
       begin
         websites.each do |website|
           if !website.match(/http:\/\/|https:\/\//)
             website = "http://#{website}"
           end
           link = "https://graph.facebook.com/?id=#{website}"
           response = fetch(link)
           json = JSON.parse response.body
           shares += json['shares'].to_i
         end
       rescue Exception=>error
         puts "FbStat#save_lifetime_data #{error.message}"
         error.backtrace[0..10].each do |m|
           logger.error "#{m}"
         end
       end
       @page = self.account.graph_api.get_object self.object_name
       res = FbPage.where(:account_id=>self.account_id).select("sum(comments) AS comments").first
       
       self.update_attributes :total_shares=>shares, :total_likes=>@page['likes'], 
         :total_comments => res.comments,
         :total_talking_about=>@page['talking_about_count']
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
      result.data = {:period=>rec.period,
          :story_likes=>rec.likes,
          :shares=>rec.shares,
          :comments=>@comments[i],
          :totals=>total
          }
      if i == 1
        rate = ((totals[1]-totals[0])*100/totals[0].to_f).round rescue 0 # 'N/A'
        rate = "#{rate} %" if rate!='N/A'
        result.data[:changes] = {
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
          :shares=>rec.shares,
          :comments=>@comments[i],
          :totals=>total
          }
          
      if (i == 1)
        rate = ((totals[1]-totals[0])*100/totals[0].to_f).round rescue 'N/A'
        rate = "#{rate} %" if rate!='N/A'
        result.values[:changes]={
           :story_likes=>@likes_change,:shares=>@shares_change,
           :comments=>@comments_change,
           :totals=>rate}
        results << result.values 
      end
    end
    results
  end

  def set_engagement_data rec
    pagelikes = rec.fan_adds_day.to_i
    comments=rec.comments + rec.replies_to_comment
    {:story_likes=>rec.likes,
     :shares=>rec.shares,
     :comments=>comments,
     :totals => (rec.likes+rec.shares+comments)
   }
  end
  
  def set_page_likes started, ended, myaccounts
    account_ids = myaccounts.map{|a| a.id}
    cond = ["post_created_time BETWEEN '#{started.beginning_of_day.to_s(:db)}' AND '#{ended.end_of_day.to_s(:db)}' "]
    sql = " DATE_FORMAT(post_created_time,'%Y-%m-%d') AS date,"   
    sql += select_account_name myaccounts
    sql += " total_likes "   
    records = FbPage.select(sql).where(cond).
      where(["account_id in (?)",account_ids]).
      group("date")
      
    records.each do |rec|  
      page_likes[rec.name]["#{rec.date}"] = rec.total_likes
    end
  end

  # For "period": "2014-07-22 - 2014-07-28"
  # The page_likes should total_likes on "2014-07-28" minus
  # total_likes on "2014-07-21"
  # This method is to get total_likes on "2014-07-21"
  def set_extra_page_likes date, myaccounts
    pre = date - 1.day
    set_page_likes pre,pre, myaccounts
    # get_select_lifetime(pre,pre, myaccounts)
  end
  
  def calculate_pagelikes rec1, rec2
    likes1 = rec1.fan_adds_day rescue 0
    likes2 = rec2.fan_adds_day rescue 0
    @pagelikes = [likes1,likes2]
  end
  
  def select_summary_sql
      select_summary_sql_page
     # select_summary_sql_post
  end
  
  def select_summary_sql_page
    sql = "max(post_created_time) as post_created_time," 
    sql += "COALESCE(sum(replies_to_comment),0) as replies_to_comment,"
    sql += "COALESCE(sum(fan_adds_day),0) as fan_adds_day,"
    sql += "COALESCE(sum(likes),0) as likes,COALESCE(sum(shares),0) as shares, "
    sql += "COALESCE(sum(comments),0) as comments, COALESCE(sum(posts),0) as posts"
  end
  
  def select_summary_sql_post
    sql = "max(post_created_time) as post_created_time," 
    sql += "COALESCE(sum(replies_to_comment),0) as replies_to_comment,"
    sql += "COALESCE(0) as fan_adds_day,"
    sql += "COALESCE(sum(likes),0) as likes,COALESCE(sum(shares),0) as shares, "
    sql += "COALESCE(sum(comments),0) as comments, COALESCE(count(*)) as posts"
  end
  
  def compute_changes rec1, rec2
    if !rec1
      @comments_change=(rec2.replies_to_comment + rec2.comments)
      @likes_change=rec2.likes
      @shares_change=rec2.shares
      @fan_adds_change=rec2.fan_adds_day
      @comments = [0,(rec2.replies_to_comment + rec2.comments)]
    elsif !rec2
      @comments_change= -1*(rec1.replies_to_comment + rec1.comments)
      @likes_change= -1*rec1.likes
      @shares_change= -1*rec1.shares
      @fan_adds_change= -1*rec1.fan_adds_day
      @comments = [(rec1.replies_to_comment + rec1.comments),0]
    else
      @comments = [(rec1.replies_to_comment + rec1.comments),
                (rec2.replies_to_comment + rec2.comments)]
      @comments_change = compute_change(@comments[1],@comments[0]) 
      @likes_change = compute_change(rec2.likes,rec1.likes)
      @shares_change = compute_change(rec2.shares,rec1.shares)
      @fan_adds_change = compute_change(rec2.fan_adds_day,rec1.fan_adds_day)
    end
  end
  
  def filter_zero record
    if record.replies_to_comment == 0 &&
       record.fan_adds_day == 0 &&
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
          :shares=>rec.shares,
          :comments=>@comments[idx],
          :totals=>total
          }
    ch = 'N/A'
    result.data[:changes] = {
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
  
=begin
  # daily insight stats 
  # consumptions_day, story_adds_day, fan_adds_day
  def self.get_insight_by_day start_date,end_date,account_ids
    cond = ["post_created_time BETWEEN '#{start_date.beginning_of_day.to_s(:db)}' AND '#{end_date.end_of_day.to_s(:db)}' "]
    sql = "'#{post_created_time.strftime('%Y-%m-%d')} AS date"
    sql += "consumptions_day,story_adds_day, fan_adds_day "
    records = self.select(sql).
      where(cond).
      where(["account_id in (?)",account_ids]).to_a
      
    arrays = []
    arrays << convert(records)
    arrays
  end
  
  # aggregated insight stats 
  # consumptions_day, story_adds_day, fan_adds_day
  def get_insight_by_period start_date,end_date,account_ids
    arr = []
    cond = ["post_created_time BETWEEN '#{start_date.beginning_of_day.to_s(:db)}' AND '#{end_date.end_of_day.to_s(:db)}' "]
    sql = "'#{start_date.strftime('%Y-%m-%d')} - #{end_date.strftime('%Y-%m-%d')}' AS period, "
    sql += "COALESCE(sum(consumptions_day),0) as consumptions_day,COALESCE(sum(story_adds_day),0) as story_adds_day, "
    sql += "COALESCE(sum(fan_adds_day),0) as fan_adds_day "
    records = FbPage.select(sql).
      where(cond).
      where(["account_id in (?)",account_ids]).to_a
    records.each do |rec|
      attr = rec.attributes
      attr.delete('id')
      arr << attr
    end
    arr
  end
  
  # insight stats 
  # story_adds_by_story_type_day
  def get_story_adds_by_story_type_day_by start_date,end_date,account_ids
    default = "{\"page post\":0,\"fan\":0,\"user post\":0,\"checkin\":0,\"other\":0}"
    cond = ["post_created_time BETWEEN '#{start_date.beginning_of_day.to_s(:db)}' AND '#{end_date.end_of_day.to_s(:db)}' "]
    sql = "post_created_time AS end_time," 
    sql = "DATE_FORMAT(post_created_time,'%Y-%m-%d') AS end_time,"   
    sql += " GROUP_CONCAT(COALESCE(story_adds_by_story_type_day,'#{default}') SEPARATOR '|') AS story_type_day "
    records = FbPage.select(sql).where(cond).
       where("story_adds_by_story_type_day != '[]'").
       where(["account_id in (?)",account_ids]).
       group('end_time').to_a
    arrays  = []   
    records.each do |rec|
      # hsh = {'name'=>'page_story_adds_by_story_type_day','date' => rec.end_time.strftime("%Y-%m-%d")}
      # hsh.merge!
      hsh = {:date=>rec.end_time}  
      hsh.merge! StoryTypeDay.sum(rec.story_type_day, start_date, end_date)
      arrays << hsh
    end
    
    arrays.flatten
    
  end
  
  # insight stats 
  # story_adds_by_story_type_period
  def get_story_adds_by_story_type_period_by start_date,end_date,account_ids
    default = "{\"page post\":0,\"fan\":0,\"user post\":0,\"checkin\":0,\"other\":0}"
    cond = ["post_created_time BETWEEN '#{start_date.beginning_of_day.to_s(:db)}' AND '#{end_date.end_of_day.to_s(:db)}' "]
    sql = "'#{start_date.strftime('%Y-%m-%d')} - #{end_date.strftime('%Y-%m-%d')}' AS period, "
    sql += "DATE_FORMAT(post_created_time,'%Y-%m-%d') AS end_time ," 
    sql += " GROUP_CONCAT(COALESCE(story_adds_by_story_type_day,'#{default}') SEPARATOR '|') AS story_type_day "
    records = FbPage.select(sql).where(cond).
      where(["account_id in (?)",account_ids]).
      where("story_adds_by_story_type_day != '[]'").
      group('end_time').
      order("post_created_time").to_a
    daily_data  = []  
    arrays = [] 
    records.each do |rec|
      hsh = {:date=>rec.end_time}
      # sum is a hash
      # story_adds_by_story_type by day
      # story_type_day is group_concat story_type_day for one day
      hsh.merge! StoryTypeDay.sum(rec.story_type_day, start_date, end_date)
      daily_data << hsh
    end
    # arrays = [daily.last]
    arrays << StoryTypeDay.sum_period(daily_data,start_date,end_date)
    arrays.flatten
  end
  
  # insight stats 
  # stories_week
  def get_stories_week_by start_date,end_date,account_ids
    cond = ["post_created_time BETWEEN '#{start_date.beginning_of_day.to_s(:db)}' AND '#{end_date.end_of_day.to_s(:db)}' "]
    sql = "DATE_FORMAT(post_created_time,'%Y-%m-%d') AS date,"    
    sql += " COALESCE(sum(stories_week),0) as stories_week "
    records = FbPage.select(sql).
       where(cond).
       where(["account_id in (?)",account_ids]).to_a

    records
  end
  
  # insight stats 
  # stories_by_story_type_week
  # return a hash
  def get_story_type_week_by start_date,end_date,account_ids
    if start_date.strftime('%y%m%d') != end_date.strftime('%y%m%d')
      raise "start_date, end_date  must be on the same day. #{start_date} and #{end_date}"
    end
    default = %{{"other":0,"fan":0,"page post":0,"user post":0,"checkin":0,"coupon":0,"mention":0,"question":0}}
    cond = ["post_created_time BETWEEN '#{start_date.beginning_of_day.to_s(:db)}' AND '#{end_date.end_of_day.to_s(:db)}' "]
    sql = "post_created_time AS end_time,"    
    sql += " COALESCE(stories_by_story_type_week,'#{default}') AS story_type_week "
    records = FbPage.select(sql).where(cond).where(["account_id in (?)",account_ids]).to_a
    arrays  = []   
    records.each do |rec|
      arrays << rec.story_type_week
    end
    sum = StoryTypeWeek.summarize arrays,start_date,end_date
    sum
  end
  
  # insight stats 
  # consumption_type_day
  def get_consumption_type_day_by start_date,end_date,account_ids
    cond = ["post_created_time BETWEEN '#{start_date.beginning_of_day.to_s(:db)}' AND '#{end_date.end_of_day.to_s(:db)}' "]
    sql = "post_created_time AS end_time,"    
    sql += " COALESCE(consumptions_by_consumption_type_day,'{}') AS consumptions "
    records = FbPage.select(sql).where(cond).where(["account_id in (?)",account_ids]).to_a
    arrays  = []   
    records.each do |rec|
      hsh = {'name'=>'page_consumptions_by_consumption_type_day','date' => rec.end_time.strftime("%Y-%m-%d")}
      hsh.merge! JSON.parse(rec.consumptions).to_h
      arrays  << ConsumptionTypeDay.new( hsh )
    end
    sum = ConsumptionTypeDay.sum arrays,start_date,end_date
    arrays.flatten
  end
  
  def get_consumption_type_period_by start_date,end_date,account_ids
    default = %{{"other_clicks":0,"video_play":0,"link_clicks":0,"photo_view":0}}
    cond = ["post_created_time BETWEEN '#{start_date.beginning_of_day.to_s(:db)}' AND '#{end_date.end_of_day.to_s(:db)}' "]
    sql = "post_created_time AS end_time,"
    sql += " COALESCE(consumptions_by_consumption_type_day,'#{default}') AS consumptions "
    records = FbPage.select(sql).where(cond).where(["account_id in (?)",account_ids]).order("post_created_time").to_a
    tmp_arrays  = []
    arrays  = []  
    records.each do |rec|
      hsh = {'name'=>'page_consumptions_by_consumption_type_day','date' => rec.end_time.strftime("%Y-%m-%d")}
      hsh.merge! JSON.parse(rec.consumptions).to_h
      tmp_arrays  << ConsumptionTypeDay.new( hsh )
    end
    arrays << ConsumptionTypeDay.sum(tmp_arrays,start_date,end_date)
    arrays.flatten
  end
=end
end
