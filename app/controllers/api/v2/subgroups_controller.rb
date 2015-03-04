class Api::V2::SubgroupsController < Api::V2::BaseController

  def index 
    arr = []
    name = ''
    model_class.where(condition1)
      .where(condition2).each do |s|
      attr = add_associate_name(s)
      arr << attr
    end
    pretty_respond arr
  end

  def condition1
    pam = {:is_active=>true}
  end

  def condition2
    cond = []
    if params[:group_id]
      ids = GroupsSubgroups.where(:group_id=>params[:group_id]).map{|gs| gs.subgroup_id}
      cond = ["id in (?)", ids]
    end
    cond
  end

  private
  def subgroup_params
    params.require(:subgroup).permit(:name, :description, :is_active)
  end

end
