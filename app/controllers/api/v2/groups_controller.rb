class Api::V2::GroupsController < Api::V2::BaseController
  include Api::ReportsHelper

  def add_related model_object
    #attach related Subgroups
    hsh = nil
    if Group === model_object
      @group_subgroups = get_group_subgroup_hash[model_object.id]
      if @group_subgroups.size > 0
        hsh = {:related_subgroups=>[]}
        @group_subgroups.each do |sg|
          hsh[:related_subgroups] << sg
        end
      end
    end
    hsh
  end

  def __option_for_select
    cond = super
    user = current_user
    cond << "(organization_id in (select organization_id from roles where roles.user_id=#{user.id}))"
    puts " Groups option_for_select #{cond}"     
    cond
  end
  
  def __add_related model_object
    #attach related Subgroups
    hsh = nil
    if Group === model_object
      sql1 = "select distinct subgroup_id from groups_subgroups where group_id = #{model_object.id}"
      subgrps = Subgroup.where("id in (#{sql1})").to_a
      if subgrps.count > 0
        hsh = {:related_subgroups=>[]}
        subgrps.each do |sg|
          hsh[:related_subgroups] << sg.attributes
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
