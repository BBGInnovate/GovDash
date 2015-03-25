class Api::V2::SubgroupsController < Api::V2::BaseController

  def add_related model_object
    #attach related Groups
    hsh = nil
    if Subgroup === model_object
      subgroup_ids = GroupsSubgroups.where(["subgroup_id = ?", model_object.id]).map{|gs| gs.subgroup_id}.uniq
      if !subgroup_ids.empty?
        hsh = {:related_groups=>[]}
        subgroup_ids.each do |sgid|
          grps = GroupsSubgroups.where(["subgroup_id in (?)", subgroup_ids]).map{ |gs| gs.group.as_json }
          hsh[:related_subgroups] = grps
        end
      end 
    end
    hsh
  end

  private
  def subgroup_params
    params.require(:subgroup).permit(:name, :description, :is_active)
  end

end
