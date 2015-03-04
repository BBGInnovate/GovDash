class Api::V2::GroupsController < Api::V2::BaseController

  def index 
    arr = []
    name = ''
    model_class.where(condition1).each do |s|
      attr = add_associate_name(s)
      arr << attr
    end
    pretty_respond arr
  end

  def condition1
    pam = {:is_active=>true}
    [:organization_id].each do |p|
      pam[p] = params[p] if params[p]
    end
    pam
  end

  private
  def group_params
    params.require(:group).permit(:name, :description, :organization_id, :is_active)
  end
  
end
