class Api::V1::RegionsController < Api::V1::BaseController
  # before_filter :authenticate_user!
  #before_filter :is_analyst?

  def add_related model_object
    hsh = nil
    if Region === model_object
      account_ids = AccountsRegion.where(["region_id = ?", model_object.id]).map{|ac| ac.account_id}.uniq
      if !account_ids.empty?
        names = AccountsRegion.where(["account_id in (?)", account_ids]).map{|ac| ac.region.name }
        related_region_names = names.uniq - [model_object.name] 
        if !related_region_names.empty?
          hsh = {:related_region_names=>[], :related_region_names=>[]}
          hsh[:related_region_names] = related_region_names
          ids = AccountsRegion.where(["account_id in (?)", account_ids]).map{|ac| ac.region.id }
          hsh[:related_region_ids] = ids.uniq - [model_object.id]
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
