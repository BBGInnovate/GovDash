class Api::V2::GroupsController < Api::V2::BaseController


  def add_related model_object
    #attach related Subgroups
    hsh = nil
    if Group === model_object
      group_ids = GroupsSubgroups.select("distinct group_id").
        where(["group_id = ?", model_object.id]).map(&:group_id).to_a
      if !group_ids.empty?
        subgroup_ids = GroupsSubgroups.select("distinct subgroup_id").
          where(["group_id in (?)", group_ids]).map(&:subgroup_id).to_a
        
        subgrps = Subgroup.where(["id in (?)", subgroup_ids]).to_a
        if !subgrps.empty?
          hsh = {:related_subgroups=>[]}
          subgrps.each do |sg|
            hsh[:related_subgroups] = sg.attributes
          end
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
