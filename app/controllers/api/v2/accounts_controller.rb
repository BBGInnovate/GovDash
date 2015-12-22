class Api::V2::AccountsController < Api::V2::BaseController
  before_filter :authenticate_user!, only: [:lookups,:new, :create, :edit, :update, :destroy]

  def index 
    arr = []
    name = ''
    @limit = params[:limit].to_i
    @offset = params[:offset].to_i
    model_class.where(condition1).
       where(condition2).
       where(condition3).
       where(condition5).
       order('name').
       limit(@limit).
       offset(@offset).
       each do |s|
       attr = filter_metadata(add_associate_name(s))
       attr[:data_collect_started] = s.send :collect_started
       arr << attr
    end
    pretty_respond arr
  end

  def create
    @data = model_class.new _params_
    update_countries_regions
    responding
  end
  
  def update
    par = _params_
    @data = model_class.find(params[:id])
    @data.update_attributes par
    update_countries_regions
    responding
  end
  
  private

  def filter_metadata attr
    arr1 = ["new_item","description","page_admin",
    "account_type_id","contact","is_active","sc_segment_id",
    "object_name_type",
    "country_ids","group_ids", "subgroup_ids","region_ids",
    "segment_names","segment_ids",
    "profile",
    :account_type_name]
    
    arr2 = ["new_item","description","page_admin",
    "account_type_id","contact","is_active","sc_segment_id",
    "object_name_type","group_names","language_names",
    "language_ids","country_names","country_ids","segment_names",
    "segment_ids","region_names","region_ids","subgroup_names",
    "profile","object_name",
    "group_ids", "subgroup_ids",
    :account_type_name]
    
    if params[:group_id] || params[:subgroup_id]
      arr = arr2
    else
      arr = arr1
    end
    arr1.each do |a|
      attr.delete a
    end
    attr
  end

  def update_countries_regions
    if @data.valid?
      @data.save
      get_contries_regions
      ids = {group: @group_ids, subgroup: @subgroup_ids, 
             language: @language_ids, country: @country_ids,
             region:  @region_ids, sc_segment: @sc_segment_ids}
      ids.each_pair do | k, val  |
         next if val.empty?
         klasse = "Accounts#{k.to_s.camelize}".constantize
         klasse.delete_all("account_id=#{@data.id}")
         the_id = "#{k.to_s}_id".to_sym
         val.each do | _id |
           ac = klasse.find_or_create_by(:account_id=>@data.id,  the_id => _id.to_i) 
         end
      end
    end
  end
=begin 
  def update_countries_regions
    if @data.valid?
      @data.save
      get_contries_regions
      if String === @country_ids
        @country_ids = @country_ids.split(',')
        @region_ids = @region_ids.split(',')
        @sc_segment_ids = @sc_segment_ids.split(',')
      end
      if !@country_ids.empty?
        AccountsCountry.delete_all("account_id=#{@data.id}")
      end
      if !@region_ids.empty?
        AccountsRegion.delete_all("account_id=#{@data.id}")
      end
      if !@sc_segment_ids.empty?
        AccountsScSegment.delete_all("account_id=#{@data.id}")
      end
      @country_ids.each do |c|
        ac = AccountsCountry.find_or_create_by(:account_id=>@data.id, :country_id=>c) 
      end
      @region_ids.each do |c|
        ac = AccountsRegion.find_or_create_by(:account_id=>@data.id, :region_id=>c)
      end
      @sc_segment_ids.each do |c|
        ac = AccountsScSegment.find_or_create_by(:account_id=>@data.id, :sc_segment_id=>c)
      end
    end
  end
=end
  
  def condition1
    pam = {:is_active=>true}
    [:account_type_id, :language_id].each do |p|
      pam[p] = params[p] if params[p]
    end
    pam
  end
  
  def condition2
    cond = []
    if params[:country_id]
      ids = AccountsCountry.where(:country_id=>params[:country_id]).map{|ac| ac.account_id}
      cond = ["id in (?)", ids]
    end
    cond
  end
  
  def condition3
    cond = []
    if params[:region_id]
      ids = AccountsRegion.where(:region_id=>params[:region_id]).map{|ac| ac.account_id}
      cond = ["id in (?)", ids]
    end
    cond
  end
  
  def condition4
    cond = []
    if params[:user_id]
      ids = AccountsUser.where(:user_id=>params[:user_id]).map{|ac| ac.account_id}
      cond = ["id in (?)", ids]
    end
    cond
  end
  
  # :group_id has no effect if :subgroup_id presents
  # params[:subgroup_id] comma separated id
  # params[:group_id] comma separated id
  def condition5
    cond = nil
    if params[:subgroup_id]
      gids = params[:subgroup_id].split(",")
      ids = AccountsSubgroup.where(["subgroup_id in (?)", gids]).
        pluck(:account_id)
      cond = ["id in (?)", ids]
    elsif params[:group_id]
      gids = params[:group_id].split(",")
      ids = AccountsGroup.where(["group_id in (?)", gids]).
        pluck(:account_id)
      cond = ["id in (?)", ids]
    end
    if cond
      cond
    else
      []
    end
  end
  
  def add_profile record
    profile = record.account_profile
    if profile
      info = {data_collect_started: record.send('collect_started')}
      info.merge! profile.attributes
      info.delete 'id'
      info.delete 'account_id'
=begin
      if info['location'] 
        if info['location'].match('=>')
          json = JSON.parse(info['location'].gsub('=>', ':'))
          info['location'] = record.location json
        end
      else
        info['location'] = ''
      end
=end
      filter_attributes info
    else
      {}
    end
  end
  
  def filter_attributes(attr)
    ['created_at','updated_at'].each do | col |
      attr.delete col
    end
    attr
  end
  
end
