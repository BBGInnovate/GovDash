module Api::ReportsHelper
  def parse_date date
    date = Time.zone.now if !date
    if String === date
      date = Time.zone.parse(date)
    end
    date
  end
  #
  # to replace fb_accounts, tw_accounts etc.
  #
  def accounts_for media_type='FacebookAccount'
    begin
      accounts.map{|a| [a.id,a.object_name] if a.media_type_name == media_type}.compact
    rescue 
      []
    end
  end
  def account_names_for media_type='FacebookAccount'
    begin
      accounts.map{|a| a.object_name if a.media_type_name==media_type }.compact
    rescue 
      []
    end
  end   
  def account_ids_for media_type='FacebookAccount'
    begin
      accounts.map{|a| a.id if a.media_type_name==media_type }.compact
    rescue 
      []
    end
  end
  def involved_countries_for media_type='FacebookAccount'
    @involved_countries_for ||=
      begin
        involved_countries.map{|rc| [rc.country.id, rc.country.name] if rc.account.media_type_name==media_type}.compact.uniq
      rescue 
        []
      end
  end
  def related_countries_for media_type='FacebookAccount'
    involved_countries_for media_type
  end
  def involved_regions_for media_type='FacebookAccount'
    @involved_regions_for ||=
      begin
        involved_regions.map{|rc| [rc.region.id, rc.region.name] if rc.account.media_type_name==media_type}.compact.uniq
      rescue 
        []
      end
  end
  def related_regions_for media_type='FacebookAccount'
    involved_regions_for media_type
  end

  def accounts
    @accounts ||=
    begin
      ReplicaAccount.where("is_active=1").select("id, name, object_name, media_type_name, contact").
        where(["id in (?)", @options[:account_ids]]).to_a
    rescue 
      []
    end
  end 
  # # remove this method?
  def input_countries
    @input_countries ||= 
    begin
      Country.where(["id in (?)", @options[:country_ids]]).map{|c| [c.id,c.name]} 
    rescue 
      []
    end
  end

  def involved_groups
    @involved_groups ||= 
      AccountsGroup.includes([:account,:group]).
          where(["account_id in (?)", @options[:account_ids]]).to_a
    Account.all_groups = @involved_groups
    ReplicaAccount.all_groups = @involved_groups
  end

  def involved_subgroups
    @involved_subgroups ||=
    begin
       AccountsSubgroup.includes([:account,:subgroup]).
          where(["account_id in (?)", @options[:account_ids]]).to_a
    rescue 
      []
    end
    Account.all_subgroups = @involved_subgroups
    ReplicaAccount.all_subgroups = @involved_subgroups
  end

  def involved_countries 
    @involved_countries  ||=
    begin
       AccountsCountry.includes([:account,:country]).
            where(["account_id in (?)", @options[:account_ids] ]).to_a
    rescue 
      []
    end
    Account.all_countries = @involved_countries
    ReplicaAccount.all_countries = @involved_countries
    @involved_countries
  end
  
  # remove this method?
  def input_regions
    @input_regions ||= 
    begin
      Region.where(["id in (?)", @options[:region_ids]]).to_a.map{|c| [c.id,c.name]} 
    rescue 
      []
    end
  end
  def involved_regions
    @involved_regions  ||=
    begin
      AccountsRegion.includes([:account,:region]).
            where(["account_id in (?)", @options[:account_ids] ]).
            to_a
    rescue 
      []
    end
    Account.all_regions = @involved_regions
    ReplicaAccount.all_regions = @involved_regions
    @involved_regions
  end

  # called by v2/regions_controller.rb
  def get_related_region_array region_id
    if !@_ac1
      @_ac1 = AccountsRegion.all.to_a
    end
    if !@_regions
      @_regions  = Region.select("id, name").all.to_a
    end
    account_ids = @_ac1.select{|a| a.region_id == region_id}.map(&:account_id).uniq
    region_ids = @_ac1.select{|a| account_ids.include? a.account_id}.map(&:region_id).uniq
    @_regions.select{|c| region_ids.include? c.id }
  end
  
  # called by v2/countries_controller.rb
  def get_related_country_array country_id
    if !@_ac1
      @_ac1 = AccountsCountry.all
    end
    if !@_countries
      @_countries  = Country.select("id, name").all.to_a
    end
    account_ids = @_ac1.select{|a| a.country_id == country_id}.map(&:account_id).uniq
    country_ids = @_ac1.select{|a| account_ids.include? a.account_id}.map(&:country_id).uniq
    @_countries.select{|c| country_ids.include? c.id }
  end
  
  def get_group_subgroup_hash
    if !@_group_subgroup_hash
      @_group_subgroup_hash = Hash.new {|h,k| h[k] = Array.new }
      res = Subgroup.select("subgroups.*, groups_subgroups.group_id").
        joins("JOIN groups_subgroups on groups_subgroups.subgroup_id = subgroups.id").
        order("groups_subgroups.group_id").to_a
      res.each do |a|
        attr = a.attributes
        group_id = attr.delete 'group_id'
        @_group_subgroup_hash[group_id] << attr
        @_group_subgroup_hash[group_id].uniq!
      end
    end
    @_group_subgroup_hash
  end
  
  def get_subgroup_group_hash
    if !@_subgroup_group_hash
      @_subgroup_group_hash = Hash.new {|h,k| h[k] = Array.new }
      res = Group.select("groups.*, groups_subgroups.subgroup_id").
         joins("JOIN groups_subgroups on groups_subgroups.group_id = groups.id").
         order("groups_subgroups.subgroup_id").to_a
      res.each do |a|
        attr = a.attributes
        subgroup_id = attr.delete 'subgroup_id'
        @_subgroup_group_hash[subgroup_id] << attr
        @_subgroup_group_hash[subgroup_id].uniq!
      end
    end
    @_subgroup_group_hash
  end
  
  def get_subgroup_region_hash
    if !@_subgroup_region_hash
      @_subgroup_region_hash = Hash.new {|h,k| h[k] = Array.new }
      res = Region.select("regions.*, subgroups_regions.subgroup_id").
            joins("JOIN subgroups_regions on subgroups_regions.region_id = regions.id").
            order("subgroups_regions.subgroup_id").to_a
      res.each do |a|
        attr = a.attributes
        subgroup_id = attr.delete 'subgroup_id'
        @_subgroup_region_hash[subgroup_id] << attr
        @_subgroup_region_hash[subgroup_id].uniq!
      end
    end
    @_subgroup_region_hash
  end
  
  def get_region_subgroup_hash 
    return @hash_array if @hash_array

    @hash_array = Hash.new {|h,k| h[k] = Array.new }
    if !@_res
      @_res = Subgroup.select("subgroups.*, subgroups_regions.region_id").
           joins("JOIN subgroups_regions on subgroups_regions.subgroup_id = subgroups.id").
           order("subgroups_regions.subgroup_id").to_a
    end
    @_res.each do |a|
      attr = a.attributes
      region_id = attr.delete 'region_id'
      @hash_array[region_id] << attr
      @hash_array[region_id].uniq!
    end
    @hash_array
  end
  
  def get_region_country_hash region_id
    if !@_rc
      @_rc = RegionsCountry.select("country_id, region_id").to_a
    end
    country_ids = @_rc.select{|c| c.region_id == region_id}.map(&:country_id)
    if !@_countries
      @_countries  = Country.select("id, name").all.to_a
    end
    @_countries.select{|c| country_ids.include? c.id }
  end
  
end
