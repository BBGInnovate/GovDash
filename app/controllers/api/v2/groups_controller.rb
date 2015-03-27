class Api::V2::GroupsController < Api::V2::BaseController


  def add_related model_object
    #attach related Subgroups
    hsh = nil
    if Group === model_object
      group_ids = GroupsSubgroups.where(["group_id = ?", model_object.id]).map{|gs| gs.group_id}.uniq
      if !group_ids.empty?
        hsh = {:related_subgroups=>[]}
        group_ids.each do |gid|
          subgrps = GroupsSubgroups.where(["group_id in (?)", group_ids]).map{ |gs| gs.subgroup.as_json }
          hsh[:related_subgroups] = subgrps
        end
      end 
    end
    hsh
  end

  def _params_
    cols = model_class.columns.map{|a| a.name.to_sym}
    params.require(model_name.to_sym).permit(cols)
  end
  
end
