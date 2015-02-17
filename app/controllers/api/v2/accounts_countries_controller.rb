class Api::V1::AccountsCountriesController < Api::V1::BaseController
  # before_filter :authenticate_user!

  private
  def accounts_country_params
    _params_
  end

end
