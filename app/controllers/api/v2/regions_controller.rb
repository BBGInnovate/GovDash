class Api::V2::RegionsController < Api::V2::BaseController
  # before_filter :authenticate_user!
  #before_filter :is_analyst?

  def add_related model_object
    hsh = {:related_region_names=>[],
           :related_subgroups=>[],
           :related_countries=>[]}       
    if Region === model_object
      account_ids = AccountsRegion.select("distinct account_id").
                      where(["region_id = ?", model_object.id]).
                      map(&:account_id).to_a
      if !account_ids.empty?
        region_ids = AccountsRegion.select("distinct region_id").
            where(["account_id in (?)", account_ids]).map(&:region_id).to_a
         
        names_pair = Region.select("id, name").where(["id in (?)", region_ids])
        names = []
        ids = []
        names_pair.each do | n |
          names << n.name
          ids << n.id
        end
        related_region_names = names - [model_object.name] 
        if !related_region_names.empty?
          hsh[:related_region_names] = related_region_names
          hsh[:related_region_ids] = ids.uniq - [model_object.id]
        end
      end
      subgroup_ids = SubgroupsRegion.select("distinct subgroup_id").
        where(["region_id = ?", model_object.id]).map(&:subgroup_id)
      
      Subgroup.where(["id in (?)", subgroup_ids]).to_a.each do |sg|
        attr = sg.attributes
        ['created_at','updated_at','is_active'].each do |col|
          attr.delete col
        end
        hsh[:related_subgroups] << attr
      end
      country_ids = RegionsCountry.select("distinct country_id").
                      where(region_id: model_object.id).
                      map(&:country_id).to_a
      if !country_ids.empty?
        Country.where(["id in (?)", country_ids]).to_a.each do |country|
          attr = country.attributes
          ['is_active','region_id'].each do |n|
            attr.delete n
          end
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
