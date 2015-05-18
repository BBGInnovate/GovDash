class Api::V2::OrganizationsController < Api::V2::BaseController
  #before_filter :authenticate_user!
  #before_filter :is_analyst?
  #before_filter :is_admin?, only: [:new, :create, :edit, :update, :destroy]

  def __option_for_select
    cond = super
    user = current_user
    cond << "(id in (select organization_id from roles where roles.user_id=#{user.id}))"
    cond
  end
  
end
