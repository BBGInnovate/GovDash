module Api::ReportsHelper
  def parse_date date
    date = Time.zone.now if !date
    if String === date
      date = Time.zone.parse(date)
    end
    date
  end
  def fb_accounts
    accounts.map{|a| [a.id,a.object_name] if a.media_type_name=='FacebookAccount' }.compact
  end 
  def tw_accounts
    accounts.map{|a| [a.id,a.object_name] if a.media_type_name=='TwitterAccount' }.compact
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
   
  def accounts
    @accounts ||=
         Account.where("is_active=1").select("id, name, object_name, media_type_name, contact").where(["id in (?)", @options[:account_ids]])
  end 
  # for countries
  def input_countries
    @input_countries ||= Country.where(["id in (?)", @options[:country_ids]]).map{|c| [c.id,c.name]} 
  end
  def involved_countries 
    @involved_countries  ||= 
         AccountsCountry.includes([:account,:country]).
            where(["account_id in (?)", @options[:account_ids] ])
  end
  def fb_involved_countries
    @fb_involved_countries ||=
        involved_countries.map{|rc| [rc.country.id, rc.country.name] if rc.account.is_facebook?}.compact.uniq
  end
  def tw_involved_countries
    @tw_involved_countries ||=
        involved_countries.map{|rc| [rc.country.id, rc.country.name] if rc.account.is_twitter?}.compact.uniq
  end
  def fb_related_countries
    fb_involved_countries # - input_countries
  end
  def tw_related_countries
    tw_involved_countries # - input_countries
  end
  
  # for regions
  def input_regions
    @input_regions ||= Region.where(["id in (?)", @options[:region_ids]]).map{|c| [c.id,c.name]} 
  end
  def involved_regions
    @involved_regions  ||= 
         AccountsRegion.includes([:account,:region]).
            where(["account_id in (?)", @options[:account_ids] ])
  end
  def fb_involved_regions
    @fb_involved_regions ||=
        involved_regions.map{|rc| [rc.region.id, rc.region.name] if rc.account.is_facebook?}.compact.uniq
  end
  def tw_involved_regions
    @tw_involved_regions ||=
        involved_regions.map{|rc| [rc.region.id, rc.region.name] if rc.account.is_twitter?}.compact.uniq
  end
  def fb_related_regions
    fb_involved_regions # - input_regions
  end
  def tw_related_regions
    tw_involved_regions # - input_regions
  end
  
end
