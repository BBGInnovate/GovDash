class Api::V2::NetworksController < Api::V2::BaseController
  # before_filter :authenticate_user!
  #before_filter :is_analyst?
  #before_filter :is_admin?, only: [:new, :create, :edit, :update, :destroy]

  private
  def network_params
    params.require(:network).permit(:name,:description,:is_active)
  end
  
end
