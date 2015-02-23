class ApplicationController < ActionController::Base
  protect_from_forgery
  respond_to :html, :json
  protected
  def is_admin?
    unless !!current_user && current_user.role_id.to_i == 1
      redirect_to "/#/users/login"
    else
      redirect_to request.referer if !!request.referer
    end
  end
  def is_analyst?
    unless !!current_user && [1,2].include?(current_user.role_id.to_i)
      redirect_to "/#/users/login"
    else
      redirect_to request.referer if !!request.referer
    end
  end
  def is_service_chief?
    unless !!current_user && [1,2,3].include?(current_user.role_id.to_i)
      redirect_to "/#/users/login"
    else
      # redirect_to request.referer if !!request.referer
    end
  end
  
end
