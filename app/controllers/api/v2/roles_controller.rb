require 'ostruct'
class Api::V2::UsersController < Api::V2::BaseController
   before_filter :authenticate_user!, :except => [:create, :show]
   skip_before_filter :is_admin?,:only => [:create, :show]
#   skip_before_filter :is_service_chief?,:only => [:create, :show]
    
  def roles
    render :json => {:roles => User.roles}, :status => 200
  end
=begin 
  def index
    arr = []
    model_class.all.each do |s|
      arr << s.attributes
    end
    pretty_respond arr
  end
  def show
    role = Role.find(params[:id])
    if role 
      user = user.merge_role
      render :json => {:user => user.send('table')}, :status => 200
    end
  end
=end
  def create
    @role = User.create(_params_)
    if @role.valid?
      respond_with @role, :location => api_roles_path
    else
      respond_with @role.errors, :location => new_roles_path
    end
  end

  def update
    role_id = params.delete(:id)
    u = Role.find role_id
    if u
      u.update_attributes _params_
    else
      u="User not found"
    end
    respond_with :api, u
  end

  def destroy
    role_id = params.delete(:id)
    begin
      respond_with :api, Role.find(role_id).destroy
    rescue
    end
  end

  private

  def _params_
    ## get_contries_regions
    cols = model_class.columns.map{|a| a.name.to_sym}
    cols = cols - [:id, :is_active, :created_at, :updated_at]
    params.require(model_name.to_sym).permit(cols)
  end
  
end
