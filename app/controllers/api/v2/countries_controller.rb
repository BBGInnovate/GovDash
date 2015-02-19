class Api::V2::CountriesController < Api::V2::BaseController
  # before_filter :authenticate_user!
  #before_filter :is_analyst?


  def add_related model_object
    hsh = nil
    if Country === model_object
      account_ids = AccountsCountry.where(["country_id = ?", model_object.id]).map{|ac| ac.account_id}.uniq
      if !account_ids.empty?
        names = AccountsCountry.where(["account_id in (?)", account_ids]).map{|ac| ac.country.name }
        related_country_names  = names.uniq - [model_object.name] 
        if !related_country_names.empty?
          hsh = {:related_country_names=>[], :related_country_names=>[]}
          hsh[:related_country_names] = related_country_names
          ids = AccountsCountry.where(["account_id in (?)", account_ids]).map{|ac| ac.country.id }
          hsh[:related_country_ids]  = ids.uniq - [model_object.id]
        end
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
