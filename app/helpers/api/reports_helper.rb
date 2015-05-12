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
      Account.where("is_active=1").select("id, name, object_name, media_type_name, contact").where(["id in (?)", @options[:account_ids]])
    rescue 
      []
    end
  end 
  # for countries
  def input_countries
    @input_countries ||= 
    begin
      Country.where(["id in (?)", @options[:country_ids]]).map{|c| [c.id,c.name]} 
    rescue 
      []
    end
  end
  def involved_countries 
    @involved_countries  ||=
    begin
       AccountsCountry.includes([:account,:country]).
            where(["account_id in (?)", @options[:account_ids] ])
    rescue 
      []
    end
  end
  
  # for regions
  def input_regions
    @input_regions ||= 
    begin
      Region.where(["id in (?)", @options[:region_ids]]).map{|c| [c.id,c.name]} 
    rescue 
      []
    end
  end
  def involved_regions
    @involved_regions  ||=
    begin
         AccountsRegion.includes([:account,:region]).
            where(["account_id in (?)", @options[:account_ids] ])
    rescue 
      []
    end
  end
  
  def get_related_country_hash
    hash_array = Hash.new {|h,k| h[k] = Array.new }
    res = Country.select("countries.*, accounts_countries.country_id").
      joins("JOIN accounts_countries on accounts_countries.country_id = countries.id").
      order("accounts_countries.country_id").to_a
    res.each do |a|
      attr = a.attributes
      country_id = attr.delete 'country_id'
      hash_array[country_id] << attr
      hash_array[country_id].uniq!
    end
    hash_array
  end
  
  def get_subgroup_group_hash 
  # TODO need more work
    hash_array = Hash.new {|h,k| h[k] = Array.new }
    res = Group.select("groups.*, groups_subgroups.subgroup_id").
       joins("JOIN groups_subgroups on groups_subgroups.group_id = groups.id").
       order("groups_subgroups.subgroup_id").to_a
    res.each do |a|
      attr = a.attributes
      subgroup_id = attr.delete 'subgroup_id'
      hash_array[subgroup_id] << attr
      hash_array[subgroup_id].uniq!
    end
    hash_array
  end
  
  def get_subgroup_region_hash 
    hash_array = Hash.new {|h,k| h[k] = Array.new }
    res = Region.select("regions.*, subgroups_regions.subgroup_id").
           joins("JOIN subgroups_regions on subgroups_regions.region_id = regions.id").
           order("subgroups_regions.subgroup_id").to_a
    res.each do |a|
      attr = a.attributes
      subgroup_id = attr.delete 'subgroup_id'
      hash_array[subgroup_id] << attr
      hash_array[subgroup_id].uniq!
    end
    hash_array
  end
  
  def get_region_subgroup_hash 
    hash_array = Hash.new {|h,k| h[k] = Array.new }
    res = Region.select("regions.*, subgroups_regions.region_id").
           joins("JOIN subgroups_regions on subgroups_regions.region_id = regions.id").
           order("subgroups_regions.region_id").to_a
    res.each do |a|
      attr = a.attributes
      region_id = attr.delete 'region_id'
      hash_array[region_id] << attr
      hash_array[region_id].uniq!
    end
    hash_array
  end
  
end
=begin
  def fb_involved_countries
    @fb_involved_countries ||=
        involved_countries.map{|rc| [rc.country.id, rc.country.name] if rc.account.is_facebook?}.compact.uniq
  end
  def tw_involved_countries
    @tw_involved_countries ||=
        involved_countries.map{|rc| [rc.country.id, rc.country.name] if rc.account.is_twitter?}.compact.uniq
  end
  def yt_involved_countries
    @yt_involved_countries ||=
        involved_countries.map{|rc| [rc.country.id, rc.country.name] if rc.account.is_youtube?}.compact.uniq
  end
  def fb_related_countries
    fb_involved_countries # - input_countries
  end
  def tw_related_countries
    tw_involved_countries # - input_countries
  end
  def yt_related_countries
    yt_involved_countries # - input_countries
  end
  
  #
  # <b>DEPRECATED:</b> Please use <tt>accounts_for</tt> instead.
  def fb_accounts
    warn Kernel.caller.first + " DEPRECATED"
    accounts.map{|a| [a.id,a.object_name] if a.media_type_name=='FacebookAccount' }.compact
  end
  # <b>DEPRECATED:</b> Please use <tt>accounts_for</tt> instead.
  def tw_accounts
    warn Kernel.caller.first + " DEPRECATED"
    accounts.map{|a| [a.id,a.object_name] if a.media_type_name=='TwitterAccount' }.compact
  end
  # <b>DEPRECATED:</b> Please use <tt>accounts_for</tt> instead.
  def yt_accounts
    warn Kernel.caller.first + " DEPRECATED"
    accounts.map{|a| [a.id,a.object_name] if a.media_type_name=='YoutubeAccount' }.compact
  end 
  def fb_account_names
    accounts.map{|a| a.object_name if a.media_type_name=='FacebookAccount' }.compact
  end   
  def fb_account_ids
    accounts.map{|a| a.id if a.media_type_name=='FacebookAccount' }.compact
  end  
  def tw_account_names
    accounts.map{|a| a.object_name if a.media_type_name=='TwitterAccount' }.compact
  end   
  def tw_account_ids
    accounts.map{|a| a.id if a.media_type_name=='TwitterAccount' }.compact
  end
  def yt_account_names
    accounts.map{|a| a.object_name if a.media_type_name=='YoutubeAccount' }.compact
  end   
  def yt_account_ids
    accounts.map{|a| a.id if a.media_type_name=='YoutubeAccount' }.compact
  end
  def fb_involved_regions
    @fb_involved_regions ||=
        involved_regions.map{|rc| [rc.region.id, rc.region.name] if rc.account.is_facebook?}.compact.uniq
  end
  def tw_involved_regions
    @tw_involved_regions ||=
        involved_regions.map{|rc| [rc.region.id, rc.region.name] if rc.account.is_twitter?}.compact.uniq
  end
  def yt_involved_regions
    @yt_involved_regions ||=
        involved_regions.map{|rc| [rc.region.id, rc.region.name] if rc.account.is_youtube?}.compact.uniq
  end
  def fb_related_regions
    fb_involved_regions # - input_regions
  end
  def tw_related_regions
    tw_involved_regions # - input_regions
  end
  def yt_related_regions
    yt_involved_regions # - input_regions
  end
=end
