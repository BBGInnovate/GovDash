class Api::V2::CountriesController < Api::V2::BaseController
  # before_filter :authenticate_user!
  #before_filter :is_analyst?


  def add_related model_object
    hsh = nil
    if Country === model_object
      sql = "select distinct account_id from accounts_countries " 
      sql += " where country_id = #{model_object.id}" 
      sql1 = "select distinct country_id from accounts_countries "
      sql1 += " where account_id in (#{sql}) "
      names_pair = Country.select("id, name").where("id in (#{sql1})")
      names = []
      ids = []
      names_pair.each do | n |
        names << n.name
        ids << n.id
      end
      related_country_names  = names.uniq - [model_object.name] 
      if !related_country_names.empty?
        hsh = {:related_country_names=>[], :related_country_names=>[]}
        hsh[:related_country_names] = related_country_names
        hsh[:related_country_ids]  = ids.uniq - [model_object.id]
      end
    end
    hsh
  end
  
  def filter_attributes(attributes)
    attributes.delete("region_id")
    attributes
  end
  
  private
  def country_params
    _params_
  end

end
