class Api::V1::ReportsController < Api::V1::BaseController
  include Api::ReportsHelper
    
  skip_before_filter :authenticate_user!
  #before_filter :is_analyst?

  before_filter :init
  
=begin
  {:options=>{
     :source=>"facebook",
     :end_date=>"2014-06-30",
     :period=>"1.week",
     :network_ids=>[1,2],
     :region_ids=>[1,2],
     :service_ids=>[1,2],
     :country_ids=>[1,2],
     :account_ids=>[1,2]
   }
  }
=end

  def index
    source = @options[:source]
    @collection = {}  # []
    if source == 'facebook'
      @collection = get_facebooks
    elsif source == 'twitter'
      @collection = get_twitters
    else
     # @collection << get_facebooks
     # @collection << get_twitters
     # @collection << get_sitecatalysts
    # @collection = get_facebooks if !!get_facebooks
     @collection.merge! get_twitters if !!get_twitters
    # @collection.merge! get_sitecatalysts if !!get_sitecatalysts
    end
    begin
      # @collection = convert(@collection)
      pretty_respond @collection
    rescue Exception=>e
      logger.error "Error #{e.message}"
      e.backtrace[0..5].each do |m|
        logger.error "#{m}"
      end
      render :status => 404
    end
  end

  def create
    index
  end
  
  private
   
  def get_facebooks
    names = fb_account_names
=begin
    hsh = {:platform => "Facebook",
           :accounts=> fb_accounts.to_h,
           :countries => fb_related_countries.to_h,
           :regions => fb_related_regions.to_h
           }       
=end
    if names.empty?
      # return hsh
      return nil
    end
    begin
      stat = FbStat.new(@options)
      sel = stat.select_by
      if !sel
        return nil
      else
        @report = {:facebook => {
             :accounts=> fb_accounts.to_h,
             :countries => fb_related_countries.to_h,
             :regions => fb_related_regions.to_h
           }}
        @report[:facebook][:values] = sel
        acc = stat.select_accounts
        @report[:facebook][:values].merge! acc if acc
        # values = stat.final_results.as_json
        # hsh[:values] = values
        # hsh
        @report
      end
    rescue Exception=>error
      logger.error error.message
      error.backtrace.each do |m|
        logger.error "#{m}"
      end
      # hsh
      nil
    end
  end
  
  def get_twitters
    names = tw_account_names
=begin
    hsh = {:platform => "Twitter",
           :accounts=>tw_accounts.to_h,
           :countries => tw_related_countries.to_h,
           :regions=> tw_related_regions.to_h}
=end
    if names.empty?
      # return hsh
      return nil
    end
    begin
      stat = TwStat.new @options
      sel = stat.select_by
      if !sel
        return nil
      else
        @report = {:twitter => {
                 :accounts=> tw_accounts.to_h,
                 :countries => tw_related_countries.to_h,
                 :regions => tw_related_regions.to_h
                }}
        @report[:twitter][:values] = sel
        acc = stat.select_accounts
        @report[:twitter][:values].merge! acc if acc
        # values = stat.final_results.as_json
        # hsh[:values] = values
        # hsh
        @report
      end
    rescue Exception=>error
      logger.error error.message
      error.backtrace.each do |m|
        logger.error "#{m}"
      end
      # hsh
      nil
    end
  end

  #Attach a Sitecatalyst Referal Traffic for all accounts
  def get_sitecatalysts
    names = fb_account_names | tw_account_names
    if names.empty?
      return nil
    end
    begin
      @report = {:sitecatalyst => {}}
      stat = ScStat.new @options
      sel = stat.select_by
      if !sel || sel.empty?
        return nil
      else
        @report[:sitecatalyst][:values] = sel 
        # hsh = {:platform => "Sitecatalyst" }
        # values = stat.final_results.as_json
        # hsh[:values] = values
        # hsh
        @report
      end
    rescue Exception=>error
      logger.error error.message
      error.backtrace.each do |m|
        logger.error "#{m}"
      end
      nil
    end
  end
  
  def init
    @report = Hash.new {|h,k| h[k] = {} }
    get_options
    # get_related_countries
  end
  
  def get_options
    @options = params[:options] || {}
    end_date = @options[:end_date]
    start_date = @options[:start_date]
    @options[:end_date] = !!end_date ? end_date : (Time.zone.now-1.days).strftime('%Y-%m-%d') 
    
    # overwrite period parameter is start_date exists
    if start_date
      diff = parse_date(@options[:end_date]) - parse_date(start_date)
      days = diff.to_i/(3600*24) + 1
      @options[:period] = "#{days}.days"
    end
    period = @options[:period]
    @options[:period] = !!period ? instance_eval(period) : 1.week
    
=begin
    if @options[:trend].match(/week/i)
      @options[:period] = 1.day
    elsif @options[:trend].match(/month/i)
      @options[:period] = 1.week
    elsif @options[:trend].match(/year/i)
      @options[:period] = 1.month
    end
=end
  
    source = @options[:source]
    @options[:source] = !!source ? source : 'all'
    @options[:trend] = 'weekly' if !@options[:trend]
    @options[:account_ids] = Account.get_account_ids @options
    @options[:accounts] = accounts
    valid_options = false
    [:network_ids, :region_ids, :country_ids, :account_ids].each do |opt|
       if (Array === @options[opt] && @options[opt].first)
         valid_options = true
         break
       end
    end
    # http_get_url = "#{request.original_url}/?#{request.request_parameters()[:report].to_param }"
  end

  def select_trend stat
    return unless @options[:trend]
    if @options[:trend].match(/week/i)
      stat.select_trend_by_day
    elsif @options[:trend].match(/month/i)
      stat.select_trend_by_week
    elsif @options[:trend].match(/year/i)
      stat.select_trend_by_month
    else
      stat.select_trend_by_day
    end
  end
  def convert collection
    arrs = []
    collection.each do | elem |
      begin
        hsh = {}
        hsh[:name] = elem[:name]
        hsh[:countries] = elem[:countries]
        hsh[:values] = []
        next if !elem[:values]
        elem[:values].each do | value |
          if Array === value
            value.each do |v|
              attributes = v.attributes rescue v
              attributes.delete('id') if attributes.respond_to?(:delete)
              hsh[:values] << attributes
            end
          else
            attributes = value.attributes rescue value
            attributes.delete('id') if attributes.respond_to?(:delete)
            hsh[:values] << attributes
          end
        end 
        arrs << hsh
      rescue Exception=>error
        logger.error error.message
        error.backtrace.each do |m|
          logger.error "#{m}"
        end
      end
    end
    arrs
  end

  def _params_
    # do nothing
  end
end
=begin
      stat.select_lifetime
      stat.insight_by
      # not used stat.story_adds_by_story_type_day
      stat.story_adds_by_story_type_period
      stat.stories_week_by
      stat.story_type_week_by
      stat.consumption_type_day_by

      values << FbPage.insight_by(@options)
      values << FbPage.story_adds_by_story_type_period(@options)
      values << FbPage.story_type_week_by(@options)
      values << FbPage.stories_week_by(@options)
      values << FbPage.consumption_type_day_by(@options)
=end
