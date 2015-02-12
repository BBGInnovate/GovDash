class Api::V1::NetworksController < Api::V1::BaseController
  # before_filter :authenticate_user!
  #before_filter :is_analyst?
  #before_filter :is_admin?, only: [:new, :create, :edit, :update, :destroy]

  private
  def network_params
    params.require(:network).permit(:name,:description,:is_active)
  end
  
end
