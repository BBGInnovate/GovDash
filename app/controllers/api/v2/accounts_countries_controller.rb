class Api::V2::AccountsCountriesController < Api::V2::BaseController
  # before_filter :authenticate_user!

  private
  def accounts_country_params
    _params_
  end

end
