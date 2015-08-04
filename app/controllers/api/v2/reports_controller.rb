=begin
 post
{"options":{
     "source":"youtube",
     "end_date":"2015-03-06",
     "period":"1.week",
     "account_ids":[141,142],
     "group_ids":[],
     "subgroup_ids":[],
     "language_ids":[],
     "region_ids":[],
     "country_ids":[],
     "sc_segment_ids":[]
   }
  }
=end

class Api::V2::ReportsController < Api::V2::BaseController
  include Api::ReportsHelper
    
  before_filter :authenticate_user!
  before_filter :enforce_user_role
  
  #before_filter :is_analyst?
  before_filter :init
  
  def index
    begin
      @collection = get_reports @options[:source]
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
  
  def enforce_user_role
    # params[:options][:organization_ids] = [] 
    #current_user.roles.map(&:organization_id)
    unless current_user.is_admin?
      # come from /api/reports
      if params[:options]
        params[:options][:organization_ids] = current_user.roles.map(&:organization_id)
      end
    end
  end
  
  private
  #
  # replace get_facebooks etc.
  #
  def get_reports source = nil
    if source && source.downcase != "all"
      medias = ["#{source.upcase}Account"]
    else
      medias = accounts.map(&:media_type_name).uniq
    end
    medias.each do |media_type_name| 
      names = account_names_for media_type_name.to_s
      if !names.empty?
        stat = get_stat_class(media_type_name)
        if stat
          sel = stat.select_by
          if sel
            rep_name=media_type_name.match('(\w+)Account')[1].downcase.to_sym
            @report[rep_name] = {
              :accounts=> accounts_for(media_type_name).to_h,
              :countries => related_countries_for(media_type_name).to_h,
              :regions => related_regions_for(media_type_name).to_h
            }
            @report[rep_name][:values] = sel
            acc = stat.select_accounts
            @report[rep_name][:values].merge! acc if acc 
          end
        end
      end
    end
    
    get_sitecatalysts
    
    @report
  end
  
  def get_stat_class media_type
    logger.debug "  Final @options=#{@options.inspect}" 
    case media_type
    when "FacebookAccount"
      FbStat.new(@options)
      # FbStatNew.new(@options)
    when "TwitterAccount"
      TwStat.new(@options)
    when "YoutubeAccount"
      YtStat.new(@options)
    else
      nil
    end
  end

  #Attach a Sitecatalyst Referal Traffic for all accounts
  def get_sitecatalysts
    names = account_names_for("FacebookAccount") |
            account_names_for("TwitterAccount")
    return nil if names.empty?
    begin
      stat = ScStat.new @options
      sel = stat.select_by
      if sel
        @report[:sitecatalyst][:values] = sel 
      end
    rescue Exception=>error
      logger.error error.message
      error.backtrace.each do |m|
        logger.error "#{m}"
      end
    end
  end
  
  def init
    @report = Hash.new {|h,k| h[k] = {} }
    get_options
  end

  def get_options
    logger.debug " BBB #{params[:options].inspect}"
    @options = params[:options] || {}
    end_date = @options[:end_date]
    start_date = @options[:start_date]
    @options[:end_date] = !!end_date ? end_date : (Time.zone.now-1.days).strftime('%Y-%m-%d') 
    @options[:start_date] = parse_date(start_date).beginning_of_day
    @options[:end_date] = parse_date(@options[:end_date]).end_of_day
    # overwrite period parameter is start_date exists
    diff = @options[:end_date] - @options[:start_date]
    @total_days = diff.to_i/(3600*24) + 1 
    if @total_days > 27
      if !@options[:start_date].sunday?
        @options[:start_date] = @options[:start_date].end_of_week.beginning_of_day
      end
      if !@options[:end_date].saturday?
        @options[:end_date]=(@options[:end_date].end_of_week-8.day).end_of_day
      end
      net_days = ((@options[:end_date] - @options[:start_date])/(3600*24)).ceil
      logger.debug "  NNN net_days=#{net_days}"
      @options[:period] = net_days.days
      @options[:trend] = 'monthly'
    else
      @options[:period] = @total_days.days
      @options[:trend] = 'daily'
    end
    @options[:account_ids] = Account.get_account_ids @options
    @options[:accounts] = accounts
    valid_options = false
    [:group_ids, :subgroup_ids, :region_ids, :country_ids, :account_ids].each do |opt|
       if (Array === @options[opt] && @options[opt].first)
         valid_options = true
         break
       end
    end
    # http_get_url = "#{request.original_url}/?#{request.request_parameters()[:report].to_param }"
  end

  def _params_
    # do nothing
  end
end
=begin
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
    def get_facebooks
    begin
      names = account_names_for "FacebookAccount"
    rescue Exception=>error
      logger.error error.message
      # error.backtrace.each do |m|
      #  logger.error "#{m}"
      #end
      return nil
    end
    
    if names.empty?
      return nil
    end
    begin
      stat = FbStat.new(@options)
      sel = stat.select_by
      if !sel
        return nil
      else
        @report = {:facebook => {
             :accounts=> accounts_for("FacebookAccount").to_h,
             :countries => related_countries_for("FacebookAccount").to_h,
             :regions => related_regiinitons_for("FacebookAccount").to_h
           }}
        @report[:facebook][:values] = sel
        acc = stat.select_accounts
        @report[:facebook][:values].merge! acc if acc
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
  
  def get_twitters
    names = tw_account_names
    if names.empty?
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
  def get_youtubes
    begin
      names = yt_account_names
    rescue Exception=>error
      logger.error error.message
      return nil
    end
    
    if names.empty?
      return nil
    end
    begin
      stat = YtStat.new(@options)
      sel = stat.select_by
      if !sel
        return nil
      else
        @report = {:youtube => {
             :accounts=> yt_accounts.to_h,
             :countries => yt_related_countries.to_h,
             :regions => yt_related_regions.to_h
           }}
        @report[:youtube][:values] = sel
        acc = stat.select_accounts
        @report[:youtube][:values].merge! acc if acc
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
=end

