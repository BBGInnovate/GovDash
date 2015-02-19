class Api::V2::AccountsRegionsController < Api::V2::BaseController
  # before_filter :authenticate_user!
  #before_filter :is_analyst?

  private
  def accounts_region_params
    _params_
  end

end
