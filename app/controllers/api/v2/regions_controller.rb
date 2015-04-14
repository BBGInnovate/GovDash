class Api::V2::RegionsController < Api::V2::BaseController
  # before_filter :authenticate_user!
  #before_filter :is_analyst?

  def add_related model_object
    hsh = nil
    hsh = {:related_region_names=>[], :related_region_names=>[],
          :related_subgroups=>[],
          :related_countries=>[]}
        
    if Region === model_object
      account_ids = AccountsRegion.where(["region_id = ?", model_object.id]).map{|ac| ac.account_id}.uniq
      if !account_ids.empty?
        # hsh = {:related_region_names=>[], :related_region_names=>[]}
          
        names = AccountsRegion.where(["account_id in (?)", account_ids]).map{|ac| ac.region.name }
        related_region_names = names.uniq - [model_object.name] 
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
        ['created_at','updated_at'].each do |col|
          attr.delete col
        end
        hsh[:related_subgroups] << attr
      end
      
      RegionsCountry.select("country_id").
        where(region_id: model_object.id).
        map(&:country_id).each | con |
          country = Country.find con
          attr = country.attributes
          hsh[:related_countries] << attr
        end
      end
    end
    hsh
  end
  
  private
  def region_params
    _params_
  end

end
