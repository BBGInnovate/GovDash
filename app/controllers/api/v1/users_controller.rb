require 'ostruct'
class Api::V1::UsersController < Api::V1::BaseController
   before_filter :authenticate_user!, :except => [:create, :show]
   skip_before_filter :is_admin?,:only => [:create, :show]
   skip_before_filter :is_service_chief?,:only => [:create, :show]
    
    
  def roles
    render :json => {:roles => User.roles}, :status => 200
  end
  
  def index
    arr = []
    model_class.all.each do |s|
      arr << s.attributes
    end
    pretty_respond arr
  end
  
  def show
    user = User.find(params[:id])
    if user 
      user = user.merge_role
      render :json => {:user => user.send('table')}, :status => 200
    end
  end

  def create
    @user = User.create(user_params)
    if @user.valid?
      sign_in(@user)
      respond_with @user, :location => api_users_path
    else
      respond_with @user.errors, :location => new_user_registration_path
    end
  end

  def update
    user_id = params.delete(:id)
    u = User.find user_id
    if u
      u.update_attributes user_params
    else
      u="User not found"
    end
    respond_with :api, u
  end

  def destroy
    respond_with :api, User.find(current_user.id).destroy
  end

  private

  def user_params
    params.require(:user).permit(:role_id,:firstname, :lastname, :email, :password, :password_confirmation, :is_active)
  end
end