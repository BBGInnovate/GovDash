class Api::V1::ServicesController < Api::V1::BaseController
  # before_filter :authenticate_user!
  #before_filter :is_analyst?

  private
  def service_params
    _params_
  end

end
