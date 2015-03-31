class Api::V2::BaseController <  ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session, :if => Proc.new { |c| c.request.format == 'application/vnd.radd.v1' }

  before_filter :controller_name
  
  append_view_path ["#{Rails.root}/app/views/api/v2/#{controller_name}", "#{Rails.root}/app/views/default"]
  
  respond_to :json
  respond_to :html
  
  # rescue_from Exception, with: :generic_exception
  rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found
  
  # params[:lang] to return shortened languages list
  def lookups
    # respond_with(model_class.all)  Country,Language
    names = Language.common_names
    
    arrs = []
    [Organization, Group, Subgroup, Region, AccountType, MediaType, Country, Language, ScSegment].each do | p |
      arr = [{'lookup'=> p.name}]
      hsh = {}
      if p.respond_to? :is_active
        cond = {:is_active=>true}
      else
        cond = {}
      end
      p.where(cond).order("name").each do |s|
        attributes = s.attributes.slice('id','name')
        if Language == p && params[:lang]
          if names.include?(attributes['name'])
            hsh = attributes
            arr = arr + [hsh]
          end
        else
          hsh = attributes
          arr = arr + [hsh]
        end 
      end
      arrs << arr
    end
    pretty_respond arrs
  end
  
  
  def index 
    # respond_with(model_class.all)
    arr = []
    name = ''
    if model_class.column_names.include? 'is_active'
      cond = {:is_active=>true}
    else
      cond = {}
    end
    model_class.where(cond).each do |s|
      attr = add_associate_name(s)
      arr << attr
    end
    pretty_respond arr
  end
  
  def add_related obj
    # raise "must be inplemented in sub class"
    nil
  end
  def filter_attributes(attr)
    # raise "must be inplemented in sub class"
    attr
  end
  
  def show
    arr = []
    record = model_class.find(params[:id])
    arr << add_associate_name(record)
    pretty_respond arr
  end

  def new
    obj = model_class.new
    name = model_name
    instance_variable_set("@#{name}", obj)
    
    respond_to do |format|
      format.html {render :layout=>'regular',:template=>'new'}
    end
  end
  
  def edit
    obj = model_class.find params[:id]
    name = model_name
    instance_variable_set("@#{name}", obj)
    respond_to do |format|
      format.html {render :layout=>'regular', :template=>'edit'}
    end
  end
  
  def update 
    @data = model_class.find(params[:id])
    #add_groups_subgroups
    responding
  end

  def create
    begin
      @data = model_class.new _params_
      #add_groups_subgroups 
    rescue
      logger.error "ERR: #{self.class.name}#create #{$!}"
    end
    responding
  end

  def destroy
    @data = model_class.find(params[:id])
    if @data.respond_to? :is_active
      @date.update_attribute :is_active, false
    else
      @data.destroy
    end
    respond_to do |format|
      format.json  { head :ok }
    end
  end

  protected
  
  def responding
    respond_to do |format|
      if @data.valid?
        if @data.new_record?
          @data.save
          msg = 'Created successfully'
        else
          @data.update_attributes( _params_ )
          msg = 'Updated successfully'
        end
        if model_name == "subgroup"
          params[:subgroup_id] = @data.id
          add_groups_subgroups
        end
        format.json {
             render :json=>{:success => msg},
             :content_type=>"text",
             :layout=>false
             }
      else
        format.json { 
             render :json=>{:error=>@data.errors.to_json},
             :content_type=>"text",
             :layout=>false
             }
      end
    end
  end
  
  #set the groups join for subgroups
  def add_groups_subgroups 
    puts "adding groups subgroups for #{model_name}"
    puts "with params:"
    puts params
      #set the groups join for subgroups
    if model_name == "subgroup" && params[:subgroup] && params[:subgroup_id]
      GroupsSubgroups.where([ "subgroup_id = ?", params[:subgroup_id] ]).delete_all
      params[:subgroup][:group_ids].each do |gid|
        GroupsSubgroups.find_or_create_by(group_id: gid, subgroup_id: params[:subgroup_id]) 
      end
    end
  end
  
  def add_associate_name(record)
    attr = filter_attributes(record.attributes)
    if Account === record
      # attr['group_name']= record.group.name if !!record.respond_to?(:group) && record.group
      unless record.groups.empty?
        attr['group_names'] =  record.groups.map(&:name)
        attr['group_ids'] =  record.groups.map(&:id)
      end
      languages = record.languages
      names = languages.map{|lang| lang.name}
      attr['language_names']= names
      ids = languages.map{|lang| lang.id}
      attr['language_ids']= ids

      countries = record.countries
      names = countries.map{|c| c.name}
      attr['country_names']= names
      ids = countries.map{|c| c.id}
      attr['country_ids']= ids

      segments = record.sc_segments.uniq
      names = segments.map{|s| s.name}
      attr['segment_names']= names
      ids = segments.map{|s| s.id}
      attr['segment_ids']= ids
      
      regions = record.regions
      names = regions.map{|c| c.name}
      attr['region_names']= names
      ids = regions.map{|c| c.id}
      attr['region_ids']= ids

      subgroups = record.subgroups
      names = subgroups.map(&:name)
      attr['subgroup_names']= names
      ids = subgroups.map(&:id)
      attr['subgroup_ids']= ids

      attr['profile'] = add_profile record
      
    elsif AccountsLanguage === record
      attr['account_name']= record.account.name if !!record.respond_to?(:account) && record.account
      attr['language_name']= record.language.name if !!record.respond_to?(:language) && record.language
    elsif AccountsCountry === record
      attr['account_name']= record.account.name if !!record.respond_to?(:account) && record.account
      attr['country_name']= record.country.name if !!record.respond_to?(:country) && record.country
    elsif AccountsUser === record
      attr['account_name']= record.account.name if !!record.respond_to?(:account) && record.account
      attr['user_name']= record.user.name if !!record.respond_to?(:user) && record.user
    elsif AccountsRegion === record
      attr['account_name']= record.account.name if !!record.respond_to?(:account) && record.account
      attr['region_name']= record.region.name if !!record.respond_to?(:region) && record.region
   elsif AccountsGroup === record
      attr['account_name']= record.account.name if !!record.respond_to?(:account) && record.account
      attr['subgroup_name']= record.group.name if !!record.respond_to?(:group) && record.group
    elsif AccountsSubgroup === record
      attr['account_name']= record.account.name if !!record.respond_to?(:account) && record.account
      attr['subgroup_name']= record.subgroup.name if !!record.respond_to?(:subgroup) && record.subgroup
    elsif AccountsScSegment === record
      attr['account_name']= record.account.name if !!record.respond_to?(:account) && record.account
      attr['sc_segment_name']= record.sc_segment.name if !!record.respond_to?(:sc_segment) && record.sc_segment
    end
    related = add_related(record)
    attr.merge!(related) if related
    attr
  end
  
  def _params_
    get_contries_regions
    cols = model_class.columns.map{|a| a.name.to_sym}
    if params[:is_active]
      if (String === params[:is_active]) 
        params[:is_active] = to_boolean(params[:is_active])
      end
    end
    params.require(model_name.to_sym).permit(cols)
  end
  
  def get_contries_regions
    record = params[model_name.to_sym]
    if model_name == 'account'
      # comma separated id
      @country_ids ||= (record.delete("country_ids") || [])
      @region_ids ||= (record.delete("region_ids") || [])
      @sc_segment_ids ||= (record.delete("sc_segment_ids") || [])
    elsif model_name == 'subgroup'
      @group_ids ||= (record.delete("group_ids") || [])
    end
  end
  
  def to_boolean(s)
    s and !!s.match(/^(true|t|yes|y|1)$/i)
  end

  def record_not_found(error)
    respond_to do |format|
      format.json { render :json => {:error => error.message}, :status => 404 }
    end
  end

  def generic_exception(error)
    respond_to do |format|
      format.json { render :json => {:error => error.message}, :status => 500 }
      format.html {render :text=>"Error! #{error.message}"}
    end
  end
  
  def pretty_respond(data)
    respond_to do |format|
     format.json { render :json=>JSON.pretty_generate(data), :layout => false }
    end
  end
  
  def is_admin?
    unless !!current_user && current_user.role_id.to_i == 1
      redirect_to "/#/users/login"
    else

    end
  end
  def is_analyst?
    unless !!current_user && [1,2].include?(current_user.role_id.to_i)
      redirect_to "/#/users/login"
    else

    end
  end
  def is_service_chief?
    unless !!current_user && [1,2,3].include?(current_user.role_id.to_i)
      redirect_to "/#/users/login"
    else
    
    end
  end
  
  def model_class
     name = params[:controller].split('/').last.titleize.singularize.gsub(" ","")
     name = name.constantize
  end
  helper_method :model_class
  
  def model_name
    name = params[:controller].split('/').last.singularize
  end
  helper_method :model_name
  
  def _edit_path
    path = send("api_#{model_name}_path")
  end
  helper_method :_edit_path
  
  def _new_path
    path = send("api_#{model_name.pluralize}_path")
  end
  helper_method :_new_path
  
  
end