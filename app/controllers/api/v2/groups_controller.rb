class Api::V2::GroupsController < Api::V2::BaseController
  # before_filter :authenticate_user!
  #before_filter :is_analyst?
  #before_filter :is_admin?, only: [:new, :create, :edit, :update, :destroy]

  private
  def group_params
    params.require(:group).permit(:name,:description,:is_active)
  end
  
end
