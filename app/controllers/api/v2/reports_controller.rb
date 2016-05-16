=begin
 get
 api/reports?options[account_ids][]=21
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
      if params[:options] && !params[:options][:organization_ids]
        params[:options][:organization_ids] = current_user.roles.map(&:organization_id)
      end
    end
  end
  
  private
  #
  # replace get_facebooks etc.
  #
  def get_reports source = nil
    # source = 'facebook'
    if source && source.downcase != "all"
      medias = ["#{source.titleize}Account"]
    else
      medias = accounts.map(&:media_type_name).uniq
    end
    medias.each do |media_type_name| 
      names = account_names_for media_type_name.to_s
      # logger.debug " Names : #{names}"
      if !names.empty?
        stat = get_stat_class(media_type_name)
        if stat
          sel = stat.select_by
          if sel
            # these two are for Account#info method
            involved_groups
            involved_subgroups
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

  def find_saturday end_date
    day = end_date
    (1..6).each do | i |
       day -= 1.day
       if day.wday == 6
          break
        end
    end
    day.end_of_day
  end
  def adjust_start_end_dates
    end_date = @options[:end_date] ? @options[:end_date] : (Time.zone.now-1.days).strftime('%Y-%m-%d') 
    @options[:end_date] = parse_date(end_date).end_of_day
    start_date = @options[:start_date]
    if !start_date 
      begin
        start_date = @options[:end_date] - instance_eval(@options[:period]) 
      rescue
        start_date = @options[:end_date] - 6.days
      end
    end
    @options[:start_date] = parse_date(start_date).beginning_of_day
    total_days = (@options[:end_date] - @options[:start_date]).to_i/(3600*24) + 1 
    if total_days > 27
      if !@options[:start_date].sunday?
        @options[:start_date] = @options[:start_date].end_of_week.beginning_of_day
      end
      if !@options[:end_date].saturday?
        @options[:end_date] = find_saturday(@options[:end_date])
      end
    elsif @options[:period] == '1.week'
      if !@options[:end_date].saturday?
        @options[:end_date] = find_saturday(@options[:end_date])
        @options[:start_date] = (@options[:end_date]-6.days).beginning_of_day+1.second
      end
    end
    total_days
  end

  def get_options
    @options = params[:options] || {}
    total_days = adjust_start_end_dates
    # overwrite period parameter
    if total_days > 27
      net_days = ((@options[:end_date] - @options[:start_date])/(3600*24)).ceil
      # logger.debug "  NNN net_days=#{net_days}"
      @options[:period] = net_days.days
      # sum data for each week
      @options[:trend] = 'weekly'
    else
      @options[:period] = total_days.days
      # sum data for each day
      @options[:trend] = 'daily'
    end
    @options[:account_ids] = ReplicaAccount.get_account_ids @options
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


