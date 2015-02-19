class Api::V2::AccountsScSegmentsController < Api::V2::BaseController
  # before_filter :authenticate_user!

  private
  def accounts_sc_segments_params
    _params_
  end

end
