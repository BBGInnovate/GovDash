require 'ostruct'

class StatDetail
  REPLICA = true
  attr_accessor :options,:account_hash,:accounts,
    # :account_name_hash, :page_likes,
    :fb_accounts, :tw_accounts, :sc_accounts, :yt_accounts, 
    :end_date, :start_date, :trend_period,
    :final_results

  def applicatio_name
    'GovDash'
  end
  
  def initialize options
     # Rails.logger.debug "  StatDetail#initialize  #{options.inspect}"
     self.options = options
     self.fb_accounts = options[:accounts].select{|a| a.media_type_name=='FacebookAccount'}
     self.tw_accounts = options[:accounts].select{|a| a.media_type_name=='TwitterAccount'}
     self.yt_accounts = options[:accounts].select{|a| a.media_type_name=='YoutubeAccount'}
          
     #use ALL given accounts for Sitecatalyst reports
     self.sc_accounts = options[:accounts]
     self.account_hash = {'ScStat'=>sc_accounts,
                          'FbStat'=>fb_accounts,
                          'FbStatNew'=>fb_accounts,
                          'TwStat'=>tw_accounts,
                          'YtStat'=>yt_accounts}
     self.end_date = parse_date(options[:end_date])
     if options[:start_date]
       self.start_date = parse_date(options[:start_date])
     end
     self.final_results = []
     self.accounts = account_hash[self.class.name] 
  end
 
  def self.select_option account_ids
    ["account_id in (?)",account_ids]
  end

  def init_struct
    result = OpenStruct.new
    result.values = Hash.new {|h,k| h[k] = {} }
    result
  end
=begin 
  def select_accounts
    # Rails.logger.debug "   AAA select_accounts"
    records = []
    trend_records = []
    data = []
    hash = {}
    dates = calculated_dates
    accounts.each do |account|
      hash = account.info
      rec5 = get_select_by(dates[0], dates[1], [account])
      rec6 = get_select_by(dates[2], dates[3], [account])
      
      unless current_exist?(rec6)
        next
      end
      value = get_detail_result(rec5, rec6)
      hash[:values] = value
      # TO replace above line
      # hash[:engagement] = value.first
      # records << rec5
      # records << rec6
      # dynamic method name
      method = self.method(trend_summarize_method)
      trend_records = method.call(trend_from_date, end_date,[account])
      hash[:trend] = get_accounts_trend_result(trend_records)
      puts "   SSSS #{hash.inspect}"
      data << hash
    end
    # final_results << {:accounts=>data}
    if !data.empty?
      {:accounts=>data}
    else
      {}
    end
  end
=end

  def select_accounts
    # Rails.logger.debug "   AAA select_accounts"
    dates = calculated_dates
    #if self.class.name.match(/(Fb)|(Tw)|(Yt)Stat/)
      data = select_none_sc_accounts dates, accounts
    #else
    #  data = select_sc_accounts dates, accounts
    #end  
    if !data.empty?
      {:accounts=>data}
    else
      {}
    end
  end
  def select_by
    # Rails.logger.debug "   AAA select_by"
    records = []
    hash = {}
    dates = calculated_dates
    # summary with dates[0], dates[1]
    # so this is one record
    rec1 = get_select_by(dates[0], dates[1], accounts)
    # summary with dates[2], dates[3]
    rec2 = get_select_by(dates[2], dates[3], accounts)
    records << rec1
    records << rec2
    unless current_exist?(rec2)
      return nil
    end
    records.flatten!

    value = get_period_result records[0], records[1]
    # select aggregate method - by_week or by_day 
    method = self.method(trend_summarize_method)
    trend_records = method.call(trend_from_date, end_date,accounts).to_a
    rec = get_trend_result(trend_records)
=begin
    for top level period
    "values": {
      "period": [
      ],
      "trend": [
      ]
=end
    hash[:period] = value
    hash[:trend] = rec unless rec.empty?
    final_results  << hash
    hash
  end

  def trend_summarize_method
    @trend_method ||=
      if options[:trend].match(/month/i)
        @trend_method = :get_select_trend_by_month
      elsif options[:trend].match(/week/i)
        @trend_method = :get_select_trend_by_week
      else
        @trend_method = :get_select_trend_by_day
      end
  end

  def select_account_name myaccount
    if myaccount.size == 1
      sql = "'#{myaccount[0].object_name}' AS name, #{myaccount[0].id} AS account_id,"
    else
      sql = " 'All' AS name, "
    end
  end
  
  def parse_date date
    if String === date
      date = Time.zone.parse(date)
    end
    date
  end

  module ClassMethods
  
  end # module ClassMethods

  # instance methods below
  
  protected
  
  def get_detail_result_value(rec5, rec6, account)
    hash = {}
    value = get_detail_result(rec5, rec6)
    hash[:values] = value
    # dynamic method name
    method = self.method(trend_summarize_method)
    trend_records = method.call(trend_from_date, end_date,[account])
    hash[:trend] = get_accounts_trend_result(trend_records)
    hash
  end
  
  def select_sc_accounts dates, myaccounts
    records = []
    trend_records = []
    data = []
    hash = {}
    dates = calculated_dates
    myaccounts.each do |account|
      hash = account.info
      rec5 = get_select_by(dates[0], dates[1], [account])
      rec6 = get_select_by(dates[2], dates[3], [account])
      unless current_exist?(rec6)
        next
      end
      hash = get_detail_result_value(rec5, rec6, account)
      data << hash
    end
    data
  end
  
  def select_none_sc_accounts dates, myaccounts
    records = []
    trend_records = []
    data = []
    hash = {}
    recs5 = get_selects_by(dates[0], dates[1], myaccounts)
    recs6 = get_selects_by(dates[2], dates[3], myaccounts)
    recs5.compact!
    recs6.compact!
    is_account = recs5[0].respond_to? :account_id
    accounts.each do |account|
      hash = account.info
      if is_account
        rec5 = recs5.detect{|a| a.account_id == account.id}
        rec6 = recs6.detect{|a| a.account_id == account.id}
      else
        rec6 = nil
        asc = AccountsScSegment.where("sc_segment_id is not null").
                where(account_id: account.id).first
        if asc
          begin
            rec5 = recs5.detect{|a| a.sc_segment_id == asc.sc_segment_id}
            rec6 = recs6.detect{|a| a.sc_segment_id == asc.sc_segment_id}
          rescue Exception=>ex
            Rails.logger.error " Rescued : #{ex.message}"
            Rails.logger.error ex.backtrace
          end
        end
      end
      unless current_exist?(rec6)
        next
      end
      hash.merge! get_detail_result_value(rec5, rec6, account)
      data << hash
    end
    data
  end
  
  def compare_date start_date,myend_date
    previous_max = start_date - 1.day
    days = ((myend_date - start_date).to_i/(60*60*24)).days
    previous_min = previous_max - days
    previous_min = previous_min.strftime "%Y-%m-%d"
    previous_max = previous_max.strftime "%Y-%m-%d"
    " CONCAT_WS(' - ','#{previous_min}','#{previous_max}') AS compare_period,"       
  end
  
  # select data for one year
  # sum over month
  def get_select_trend_by_month start_date,myend_date, myaccounts
    if myend_date.day != myend_date.end_of_month.day
    #   myend_date = (myend_date - 1.month)
    end
    account_ids = myaccounts.map{|a| a.id}
    min = "DATE_FORMAT(min(#{self.class.created_at}),'%Y-%m-%d')"
    max = "DATE_FORMAT(max(#{self.class.created_at}),'%Y-%m-%d')"
        
    cond = ["#{self.class.created_at} BETWEEN '#{start_date.beginning_of_month.to_s(:db)}' AND '#{myend_date.end_of_month.to_s(:db)}' "]
    sql = " #{max} AS trend_date,"   
    sql += " CONCAT_WS(' - ',#{min},#{max}) AS period,"
    sql += compare_date(start_date,myend_date)  
    sql += " 'month' AS trend_type,"      
    sql += "MONTH(#{self.class.created_at}) AS month_number, "
    sql += select_account_name myaccounts
    sql += select_summary_sql
    
    records = self.class.table_class.select(sql).where(cond).
      where(self.class.select_option account_ids).
      group("month_number")

    records
  end

  def get_select_trend_by_week start_date,myend_date, myaccounts
    account_ids = myaccounts.map{|a| a.id}
    min = start_date.strftime "%Y-%m-%d"
    max = myend_date.strftime "%Y-%m-%d"
    User.logger.debug "    get_select_trend_by_week"
    cond = ["#{self.class.created_at} BETWEEN '#{start_date.beginning_of_day.to_s(:db)}' AND '#{myend_date.end_of_day.to_s(:db)}' "]
    sql = " DATE_FORMAT(max(#{self.class.created_at}),'%Y-%m-%d') AS trend_date,"     
    sql += " CONCAT_WS(' - ','#{min}','#{max}') AS period,"
    sql += compare_date(start_date,myend_date)
    sql += " 'week' AS trend_type,"   
    sql += "1 + DATEDIFF(#{self.class.created_at}, '#{min}') DIV 7  AS week_number, "
    sql += "'#{min}' + INTERVAL (DATEDIFF(#{self.class.created_at}, '#{min}') DIV 7) WEEK AS week_start_date,"
    sql += select_account_name myaccounts
    sql += select_summary_sql
    records = self.class.table_class.select(sql).where(cond).
      where(self.class.select_option account_ids).
      group("week_number")
    records
  end

  def get_select_trend_by_day start_date,end_date, myaccounts
    User.logger.debug "    get_select_trend_by_day"
    account_ids = myaccounts.map{|a| a.id}
    cond = ["#{self.class.created_at} BETWEEN '#{start_date.beginning_of_day.to_s(:db)}' AND '#{end_date.end_of_day.to_s(:db)}' "]
    sql = "DATE_FORMAT(#{self.class.created_at},'%Y-%m-%d') AS trend_date, "
    sql += " 'day' AS trend_type,"    
    sql += select_account_name myaccounts   
    sql += select_summary_sql
    records = self.class.table_class.select(sql).where(cond).
      where(self.class.select_option account_ids).
      group("trend_date").to_a
    records = fill_missing_rows records,start_date,end_date
    records
  end

  # start_date,end_date : Time object
  # myaccounts : array of Account object
  # return one active_record
  def get_select_by start_date,myend_date,myaccounts
    account_ids = myaccounts.map{|a| a.id}
    cond = ["#{self.class.created_at} BETWEEN '#{start_date.beginning_of_day.to_s(:db)}' AND '#{myend_date.end_of_day.to_s(:db)}' "]
    sql = "'#{start_date.strftime('%Y-%m-%d')} - #{myend_date.strftime('%Y-%m-%d')}' AS period, "
    sql += compare_date(start_date,myend_date)
    sql += select_account_name myaccounts
    sql += " 'placeholder' as changes,"
    sql += select_summary_sql
    record = self.class.table_class.select(sql).where(cond).
      where(self.class.select_option account_ids).first
    record = filter_zero record
  end

  # start_date,end_date : Time object
  # myaccounts : array of Account object
  # return array active_record
  def get_selects_by start_date,myend_date,myaccounts
    account_ids = myaccounts.map{|a| a.id}
    cond = ["#{self.class.created_at} BETWEEN '#{start_date.beginning_of_day.to_s(:db)}' AND '#{myend_date.end_of_day.to_s(:db)}' "]
    sql = "'#{start_date.strftime('%Y-%m-%d')} - #{myend_date.strftime('%Y-%m-%d')}' AS period, "
    sql += compare_date(start_date,myend_date)
    sql += select_account_name myaccounts
    sql += " 'placeholder' as changes,"
    sql += select_summary_sql
    if self.class.name != 'ScStat'
      records = self.class.table_class.select(sql).where(cond).
        where(self.class.select_option account_ids).
        group(:account_id).to_a
    else
      records = self.class.table_class.select(sql).where(cond).
        where(self.class.select_option account_ids).
        group(:sc_segment_id).to_a
    end
    myrecords = []
    records.each do |record|
      myrecords << filter_zero(record)
    end
    myrecords
  end
  
  def select_summary_sql
    arr = ["account_id"]
    self.class.data_columns.each_pair do | col, _as |
      arr << "COALESCE(sum(#{col}),0) as #{_as}" 
    end
    arr.join(',')
  end

  def get_detail_result rec1, rec2
    Rails.logger.debug "   StatDetail#get_detail_result"
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
        rate = ((totals[1]-totals[0])*100/totals[0].to_f).round rescue 0 
        rate = "#{rate} %" if rate!='N/A'
        hash = {:totals=>rate}
        self.class.data_columns.each_pair do |col,_as|
          hash[_as.to_sym] = instance_variable_get("@#{_as}_change")
        end
        result.values[:changes] = hash
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
      result.values = {:period=>rec.period,
        :previous_period=>rec.compare_period}
      result.values.merge! set_engagement_data(rec)
      totals << result.values[:totals]
      if i == 1
        rate = ((totals[1]-totals[0])*100/totals[0].to_f).round rescue 0
        rate = "#{rate} %" if rate!='N/A'
        hash = {:totals=>rate}
        self.class.data_columns.each_pair do |col, _as|
          hash[_as.to_sym] = instance_variable_get("@#{_as}_change")
        end
        result.values[:changes] = hash
        results << result.values      
      end  
    end
    results
  end

  def filter_attributes rec_hash
    self.class.data_columns.each_pair do |key, _as|
      rec_hash.delete(_as)
    end
    rec_hash
  end

  def filter_zero record
    zero_count = 0
    self.class.data_columns.each_pair do | col,_as |
      if record.send(_as) == 0
        zero_count += 1
      end
    end
    if zero_count == self.class.data_columns.keys.count
      nil
    else
      record
    end
  end

  def set_engagement_data rec, remove = ''
    hash = {}
    begin
      totals = 0
      self.class.data_columns.each_pair do |col, _as|
        if _as != remove
          val = rec.send(_as)
          totals += val
          hash[_as.to_sym] = val
        end
      end
      hash[:totals]=totals
    rescue
    end
    hash
  end

  def missing_record rec
    results = []
    result = init_struct
    result.values = {:period=>rec.period,
                     :previous_period=>rec.compare_period}
    result.values.merge! set_engagement_data(rec)
    ch = 0
    hash = {:totals=>ch}
    self.class.data_columns.each_pair do |col, _as|
      hash[_as.to_sym] = ch
    end
    result.values[:changes] = hash  
    results << result.data
    msg = " #{applicatio_name} #{self.class.name} Data missing in #{rec.name} #{previous_period}"
    ErrorLog.to_error msg,msg,3
    results
  end

  def fake_record date,trend_type
    max = parse_date date
    min = max - 6.days
    hash = {}
    self.class.data_columns.each_pair do |col,_as|
      hash[_as.to_sym] = 0
    end
    rec = OpenStruct.new hash
    rec.week_start_date = min
    rec.id = nil
    rec.trend_date = date
    rec.trend_type = trend_type
    rec.totals = 0
    rec
  end

  def get_account_name myaccounts
    if myaccounts.size == 1
      name = myaccounts[0].name
    else
      name = 'All'
    end
  end
  
  def get_trend_name record
    case (record.trend_type rescue 'week')
    when 'week','month'
      # from_date - to_date
      name = :period
    else
      # day by day data
      name = :date
    end
    trend = :trend
    [trend, name]
  end
  def date_value rec 
    # Rails.logger.debug "   AAA date_value #{rec.trend_type} - #{rec.trend_date}"
    date = parse_date rec.trend_date
    case rec.trend_type
      when 'week'
        if String === rec.week_start_date
          week_start_date = Time.zone.parse rec.week_start_date
        else
          week_start_date = rec.week_start_date
        end
        ended = (week_start_date+6.days).strftime('%Y-%m-%d')
        value = "#{week_start_date.strftime('%Y-%m-%d')} - #{ended}"
      when 'month'
        started = date.beginning_of_month.strftime('%Y-%m-%d')
        ended = date.end_of_month.strftime('%Y-%m-%d')        
        value = "#{started} - #{ended}"
      else
        value = rec.trend_date
    end
    value
  end
  
=begin
  def current_from_date
    end_date.change_to(options[:period],"ago")
  end
  
  def period1_from_date
    current_from_date.change_to(options[:period],"ago")+1.day
  end
  def period1_end_date 
    current_from_date
  end
  def period2_from_date
    current_from_date + 1.day
  end
  def period2_end_date
    end_date
  end
=end
  def current_from_date
    options[:start_date]
  end
  
  def period1_from_date
    n = (period2_end_date.beginning_of_day - period2_from_date.beginning_of_day).to_i/3600/24
    period1_end_date - n.days
  end
  def period1_end_date 
    period2_from_date.end_of_day - 1.day
  end
  def period2_from_date
    current_from_date
  end
  def period2_end_date
    options[:end_date]
  end

  
  # for two end dates in current period and
  # two end dates in previous period
  # from previous_from_date to current_from_date
  # from previous_end_date to end_date

  def calculated_dates
    [period1_from_date,period1_end_date,
     period2_from_date, period2_end_date]  
  end

  def compute_change num2,num1
    if num2 == 0
      res  = '0 %'
    elsif num1 == 0
      res = 'N/A'
    else
      res = ((num2 - num1)*100/num1.to_f).round
      res = "#{res} %"  
    end
  end
  
  def fetch(url, limit = 3)
    raise ArgumentError, 'HTTP redirect too deep' if limit == 0
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 180
    # http.set_debug_output($stdout)
    if uri.scheme == 'https'
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    response = http.get(uri.request_uri)
    case response
       when (Net::HTTPOK || Net::HTTPSuccess)
          return response
       when Net::HTTPRedirection
          new_url = redirect_url(response)
          # Rails.logger.debug "Redirect to " + new_url
          return fetch(new_url, limit - 1)
       else
         response.error!
    end
    response
  end
  
  def fill_missing_rows records, start_date,end_date
    if !records || records.empty?
      return []
    end
    avail_dates = records.map{|rec| rec.trend_date}
    if self.trend_period == 'month'
      increment = 1.month
      current_date = start_date.end_of_month
    elsif self.trend_period == 'week'
      increment = 1.week
      current_date = start_date.end_of_day+6.days
    else
      increment = 1.day
      current_date = start_date.end_of_day
    end  
    while current_date <= end_date.end_of_day
      date = current_date.strftime('%Y-%m-%d')
      if !avail_dates.include? date
        rec = fake_record date,self.trend_period
        records << rec
      end
      current_date += increment
      if self.trend_period == 'month'
        current_date = current_date.end_of_month
      else
        current_date = current_date.end_of_day
      end
    end
    records.sort_by! { |m| m.trend_date }
    records
  end
  
  def get_accounts_trend_result records
    hash = {}
    results = []
    trend, name = get_trend_name records[0]
    records.each do |rec|
      value = date_value rec
      result = init_struct
      result.values = {name=>value}
      if FbPage === rec
        # page_likes not considered as engagement data
        remove = 'page_likes'
      else
        remove = ''
      end
      result.values.merge! set_engagement_data(rec,remove)
      # leave only :totals
      filter_attributes result.values
      results << result.values
    end
    results
  end
  
  def get_trend_result records
    if records.empty?
      return []
    end
    data = []
    hash = {}
    trend, name = get_trend_name records[0]
    records.each do |rec|
      value = date_value(rec)
      # value is for trend period
      # value=value.split(' - ').last
      # Rails.logger.debug "  QAAA #{value}"
      result = init_struct
      result.name = rec.name if (rec.name != 'All')
      result.data_type = 'trend'
      result.date = rec.trend_date
      result.values = {name=>value}
      if FbPage === rec
        # page_likes not considered as engagement data
        remove = 'page_likes'
      else
        remove = ''
      end
      result.values.merge! set_engagement_data(rec,remove)
      # leave only :totals
      filter_attributes result.values
      data << result.values
    end
    data
  end
  
  def trend_from_date
    if options[:trend].match(/year/i)  
      month_from_date
    elsif options[:trend].match(/month/i)
      week_from_date
    else
      day_from_date
    end
  end
  
  def month_from_date
    self.end_date.change_to(12.months, "ago")+1.day
  end 
  def week_from_date
    self.end_date.change_to(4.weeks, "ago")+1.day
  end 
  def day_from_date
    if options[:start_date]
      self.start_date
    elsif options[:period]
      peri = options[:period]
      self.end_date.change_to(peri,"ago")
    else
      self.end_date.change_to(6.days,"ago")
    end
  end
  
  private
   
  # month by month trend in one year
  def select_trend_by_month
    self.trend_period  = 'month'
    records = []
    records = get_select_trend_by_month(month_from_date, end_date, accounts)
    records = fill_missing_rows(records, month_from_date, end_date)
    records.flatten
  end
  
  # week by week trend in one month
  def select_trend_by_week
    self.trend_period  = 'week'
    records = []
    records = get_select_trend_by_week( week_from_date, end_date, accounts)
    records = fill_missing_rows(records, week_from_date, end_date)      
    records.flatten
  end
  
  # day by day trend 
  def select_trend_by_day
    self.trend_period  = 'day'
    records = []
    records = get_select_trend_by_day( day_from_date, end_date, accounts)
    records = fill_missing_rows(records, day_from_date, end_date)      
    records.flatten
  end
  
  def select_lifetime
    records = []
    dates = calculated_dates
    dates.each_with_index do | date, i |
      rec = get_select_lifetime(date,date,accounts)
      if (i % 2) == 1
        records << rec
      end
    end
    results = get_lifetime_result records[0], records[1]
    final_results << {:lifetime=>results}
    records.flatten
  end
  
  def compute_changes rec1,rec2
    self.class.data_columns.each_pair do |col, _as|
      val =  compute_change(rec2.send(_as),rec1.send(_as)) rescue 0
      instance_variable_set("@#{_as}_change", val)
    end
  end  

  def previous_period
    from_date = self.end_date - 2*self.options[:period] + 1.day
    to_date = from_date + self.options[:period] 
    @previous_period = " #{from_date} - #{to_date}"
  end
  
  def current_period
    from_date = self.end_date - self.options[:period] + 1.day
    to_date = from_date + self.options[:period] 
    @current_period = " #{from_date} - #{to_date}"
  end
  
  def current_exist? rec
    if !rec
      User.logger.error "Data missing in #{current_period}"
      false
    else
      true
    end
  end
  
  def print_results
    puts final_results.inspect
  end
  
end
=begin
  def hash_tree
    Hash.new do |hash, key|
      hash[key] = hash_tree
    end
  end
=end
