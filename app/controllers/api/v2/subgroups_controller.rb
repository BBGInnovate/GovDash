class Api::V2::SubgroupsController < Api::V2::BaseController

  #after_save :set_groups, :only => [:new, :edit]

  #create/update the groups_subgroups join after saving a new subgroup
  def set_groups
    puts "inside set_groups"
    puts params[:group_ids]
    puts "group ids above"
    # gs = @subgroup.groups_subgroups
    # gs.each do |g|
    #puts subgroup_params

  end

  #attach related Groups output
  def add_related model_object
    hsh = nil
    if Subgroup === model_object
      subgroup_ids = GroupsSubgroups.where(["subgroup_id = ?", model_object.id]).map{|gs| gs.subgroup_id}.uniq
      if !subgroup_ids.empty?
        hsh = {:related_groups=>[]}
        subgroup_ids.each do |sgid|
          grps = GroupsSubgroups.where(["subgroup_id in (?)", subgroup_ids]).map{ |gs| gs.group.as_json }
          hsh[:related_groups] = grps
        end
      end 
    end
    hsh
  end

  private
  def subgroup_params
    #params.require(:subgroup).permit(:name, :description, :is_active)
    _params_
  end

end
