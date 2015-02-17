class Api::V1::AccountsScSegmentsController < Api::V1::BaseController
  # before_filter :authenticate_user!

  private
  def accounts_sc_segments_params
    _params_
  end

end
