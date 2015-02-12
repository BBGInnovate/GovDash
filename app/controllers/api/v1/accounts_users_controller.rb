class Api::V1::AccountsUsersController < Api::V1::BaseController
  # before_filter :authenticate_user!
  #before_filter :is_analyst?

  private
  def accounts_user_params
    _params_
  end

end
