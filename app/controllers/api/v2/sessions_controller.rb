class Api::V2::SessionsController < Devise::SessionsController
  protect_from_forgery with: :null_session, :if => Proc.new { |c| c.request.format == 'application/vnd.radd.v1' }

  def create
    warden.authenticate!(:scope => resource_name, :recall => "#{controller_path}#failure")
    user = current_user.merge_role
    num = Rails.configuration.new_user_confirmation_expires_in
    if current_user.reset_password_sent_at
      if (Time.zone.now <= current_user.reset_password_sent_at + num.hours)
        render :status => 200, :json => { :success => true, :info => "Logged in with temporary password", :user => user.send('table') }
      else
        # current_user = nil
        # user = nil
        render :status => 406, :json => { :success => false, :info => "Temporary password expired", :user => {"email": current_user.email} }
      end
    else
      # current_user.update_column :reset_password_sent_at, nil
      render :status => 200, :json => { :success => true, :info => "Logged in", :user => user.send('table') }
    end
  end

  def destroy
    warden.authenticate!(:scope => resource_name, :recall => "#{controller_path}#failure")
    sign_out
    render :status => 200, :json => { :success => true, :info => "Logged out", :csrfParam => request_forgery_protection_token, :csrfToken => form_authenticity_token }
  end

  def failure
    render :status => 401, :json => { :success => false, :info => "Login Credentials Failed" }
  end

  def show_current_user
    warden.authenticate!(:scope => resource_name, :recall => "#{controller_path}#failure")
    render :status => 200, :json => { :success => true, :info => "Current User", :user => current_user }
  end
end
