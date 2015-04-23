class Api::V2::RegionsController < Api::V2::BaseController
  # before_filter :authenticate_user!
  #before_filter :is_analyst?

  def add_related model_object
    hsh = {:related_region_names=>[],
           :related_subgroups=>[],
           :related_countries=>[]}       
    if Region === model_object
      sql1 = "select distinct account_id from accounts_regions where region_id = #{model_object.id}"
      sql2 = "select distinct region_id from accounts_regions "
      sql2 += " where account_id in (#{sql1})"
      names_pair = Region.select("id, name").where("id in (#{sql2})").to_a
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

      sql1= "select distinct subgroup_id from subgroups_regions "
      sql1 += " where region_id = #{model_object.id} "
      Subgroup.where("id in (#{sql1})").to_a.each do |sg|
        attr = sg.attributes
        ['created_at','updated_at','is_active'].each do |col|
          attr.delete col
        end
        hsh[:related_subgroups] << attr
      end
      sql1 = "select distinct country_id from regions_countries "
      sql1 += "  where region_id=#{model_object.id}"
      Country.where("id in (#{sql1})").order("id").to_a.each do |country|
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
