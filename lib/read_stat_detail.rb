require 'ostruct'

module ReadStatDetail
  
  attr_accessor :options,:account_hash,:accounts,:account_name_hash, 
    :fb_accounts, :tw_accounts, :sc_accounts, :yt_accounts, 
    :fb_accounts,:end_date, :start_date,:page_likes,:trend_period,
    :final_results
    
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  def initialize options
     self.options = options
     self.fb_accounts = options[:accounts].select{|a| a.media_type_name=='FacebookAccount'}
     self.tw_accounts = options[:accounts].select{|a| a.media_type_name=='TwitterAccount'}
     self.yt_accounts = options[:accounts].select{|a| a.media_type_name=='YoutubeAccount'}
          
     #use ALL given accounts for Sitecatalyst reports
     self.sc_accounts = options[:accounts]
     self.account_hash = {'ScStat'=>sc_accounts,
                          'FbStat'=>fb_accounts, 
                          'TwStat'=>tw_accounts,
                          'YtStat'=>yt_accounts}
     self.end_date = parse_date(options[:end_date])
     if options[:start_date]
       self.start_date = parse_date(options[:start_date])
     end
     # self.page_likes = hash_tree
     self.final_results = []
     self.accounts = account_hash[self.class.name]
     # self.account_name_hash = Hash[accounts.collect { |a| [a.id, a.name] }]
     
  end
 
  def init_struct
    result = OpenStruct.new
    # result.data_type = 'lifetime'
    result.values = Hash.new {|h,k| h[k] = {} }
    result
  end
    
  def select_accounts
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
      
      records << rec5
      records << rec6
      # dynamic method name
      method = self.method(trend_select_method)
      trend_records = method.call(trend_from_date, end_date,[account])
      trend_records = fill_missing_rows(trend_records,trend_from_date, end_date)      
      
      # trend_records = select_trend_by([account])
      # account level trend parallel to values
      hash[:trend] = get_accounts_trend_result(trend_records)
      data << hash
    end
    final_results << {:accounts=>data}
    if !data.empty?
      {:accounts=>data}
    else
      {}
    end
  end
  
  def select_by
    records = []
    hash = {}
    dates = calculated_dates
    rec1 = get_select_by(dates[0], dates[1], accounts)
    rec2 = get_select_by(dates[2], dates[3], accounts)
    
    records << rec1 # if rec1
    records << rec2 # if rec2
    
    unless current_exist?(rec2)
      return nil
    end
    records.flatten!
    ## set_page_likes end_date-3.days, end_date, accounts
    
    value = get_period_result records[0], records[1]
    hash[:period] = value
    # TO replace abour line
    # hash[:engagement] = value.first
    
    method = self.method(trend_select_method)
    trend_records = method.call(trend_from_date, end_date,accounts).to_a
    rec = get_trend_result(trend_records)
    hash[:trend] = rec unless rec.empty?
    final_results  << hash
    # records
    hash
  end

  def trend_select_method
    @trend_method ||=
      if options[:trend].match(/year/i)
        @trend_method = :get_select_trend_by_month
      elsif options[:trend].match(/month/i)
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
      # date = Time.zone.now if !date
      if String === date
        date = Time.zone.parse(date)
      end
      date
    end

  module ClassMethods
  
  end # module ClassMethods

  # instance methods below
  
  protected

  def get_account_name myaccounts
    if myaccounts.size == 1
      name = myaccounts[0].name
    else
      name = 'All'
    end
  end
  
  def get_trend_name record
    case (record.trend_type rescue 'week')
      when 'week'
        # trend = :monthly_trend
        name = :period
      when 'month'
        # trend = :yearly_trend
        name = :period
      else
        # trend = :weekly_trend
        # day by day data
        name = :date
    end
    trend = :trend  # overwrite
    [trend, name]
  end
  def date_value rec 
    date = parse_date rec.trend_date
    case rec.trend_type
      when 'week'
        ended = (rec.week_start_date+6.days).strftime('%Y-%m-%d')
        value = "#{rec.week_start_date} - #{ended}"
      when 'month'
        started = date.beginning_of_month.strftime('%Y-%m-%d')
        ended = date.end_of_month.strftime('%Y-%m-%d')        
        value = "#{started} - #{ended}"
      else
        value = rec.trend_date
    end
    value
  end
  
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
          logger.debug "Redirect to " + new_url
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
=begin
    if records.first
      trend_type = records.first.trend_type 
    elsif ScStat === self
      trend_type = 'day'
    else
      trend_type = 'week'
    end
=end
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
      result.values.merge! set_engagement_data(rec)
      # leave only :totals
      filter_attributes result.values
      results << result.values
    end
    results
    #hash[trend] = results
    #hash
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
      rec.trend_date
      result = init_struct
      result.name = rec.name if (rec.name != 'All')
      result.data_type = 'trend'
      result.date = rec.trend_date
      result.values = {name=>value}
      result.values.merge! set_engagement_data(rec)
      # leave only :totals
      filter_attributes result.values
      data << result.values
    end
    data
    #hash[trend]=data
    #hash
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
  
    
  # # month by month trend in one year
  def select_trend_by_month
    self.trend_period  = 'month'
    records = []
    records = get_select_trend_by_month(month_from_date, end_date, accounts)
    records = fill_missing_rows(records, month_from_date, end_date)
    records.flatten
  end
  
  # # week by week trend in one month
  def select_trend_by_week
    self.trend_period  = 'day'
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
      ## if FbStat === self && i==0
      ##   set_extra_page_likes date, accounts
      ## end
      rec = get_select_lifetime(date,date,accounts)
      ## set_page_likes rec
      if (i % 2) == 1
        records << rec
      end
    end
    results = get_lifetime_result records[0], records[1]
    final_results << {:lifetime=>results}
    records.flatten
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
