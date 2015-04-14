class Api::V2::RegionsController < Api::V2::BaseController
  # before_filter :authenticate_user!
  #before_filter :is_analyst?

  def add_related model_object
    hsh = {:related_region_names=>[], 
           :related_region_names=>[],
           :related_subgroups=>[],
           :related_countries=>[]}       
    if Region === model_object
      account_ids = AccountsRegion.select("account_id").
                      where(["region_id = ?", model_object.id]).
                      map(&:account_id).uniq
      if !account_ids.empty?
        names = AccountsRegion.where(["account_id in (?)", account_ids]).
           map{|ac| ac.region.name }.uniq
        related_region_names = names - [model_object.name] 
        if !related_region_names.empty?
          hsh[:related_region_names] = related_region_names
          ids = AccountsRegion.where(["account_id in (?)", account_ids]).map{|ac| ac.region.id }
          hsh[:related_region_ids] = ids.uniq - [model_object.id]
        end
      end
      subgroup_ids = SubgroupsRegion.select("subgroup_id").
        where(["region_id = ?", model_object.id]).map(&:subgroup_id).uniq
      
      Subgroup.where(["id in (?)", subgroup_ids]).to_a.each do |sg|
        attr = sg.attributes
        ['created_at','updated_at','is_active'].each do |col|
          attr.delete col
        end
        hsh[:related_subgroups] << attr
      end
      
      country_ids = RegionsCountry.select("country_id").
                      where(region_id: model_object.id).
                      map(&:country_id).uniq
      country_ids.each do | con |
        country = Country.find con
        attr = country.attributes
        ['is_active','region_id'].each do |n|
          attr.delete n
        end
        hsh[:related_countries] << attr
      end
    end
    hsh
  end
  
  private
  def region_params
    _params_
  end

end
