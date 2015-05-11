require 'ostruct'
class Api::V2::UsersController < Api::V2::BaseController
   before_filter :authenticate_user!, :except => [:create, :show]
   skip_before_filter :is_admin?,:only => [:create, :show]
   skip_before_filter :is_service_chief?,:only => [:create, :show]
    
    
  def roles
    render :json => {:roles => User.roles}, :status => 200
  end
  
  def index
    arr = []
    model_class.all.each do |s|
      arr << add_associate_name(s)
    end
    pretty_respond arr
  end
  
  def __show
    user = User.find(params[:id])
    if user 
      user = user.merge_role
      render :json => {:user => user.send('table')}, :status => 200
    end
  end

  def show
    arr = []
    record = model_class.find(params[:id])
    arr << add_associate_name(record)
    pretty_respond arr
  end
  
=begin
{"user":{
"email":"liwen@bbg.gov",
"password":"aaaaaaa",
"password_confirmation":"aaaaaaa",
"roles":["bbg"]
}}
=end

  def create
    pars = _params_
    @roles = pars.delete 'roles'
    @email = pars.delete 'email'
    begin
      @user = User.find_or_create_by email: @email
      @user.update_attributes pars
      if @user.is_admin?
        Organization.all.each do | org |
          @user.roles.find_or_create_by organization_id: org.id
        end
      elsif @roles
        reset_roles @user, @roles
      end
      sign_in(@user)
      # respond_with @user, :location => api_users_path
      params[:id] = @user.id
      show
    rescue
      respond_with @user.errors, :location => new_user_registration_path
    end
  end

  def update
    # user_id = params.delete(:id)
    @roles = params[:user].delete 'roles'
    u = User.find params[:id]
    if u
      u.update_attributes(_params_)
      reset_roles u, @roles
    else
      u="User not found"
    end
    show
    # respond_with :api, u
  end

  def destroy
    if current_user && current_user.is_admin?
      respond_with :api, User.find(current_user.id).destroy
    else
      respond_with :api, 'Not permiited'
    end
  end

  protected
  def reset_roles user, roles=nil
    if roles && !roles.empty?
      user.roles.clear
      roles.each do |ro|
        og = Organization.find_by name: ro.strip
        if og
          user.roles.find_or_create_by organization_id: og.id
        end
      end
    end
  end
  
  def delete_attributes attr
    attr = super
    ['user_id','organization_id','weight','role_id',
     "encrypted_password","reset_password_token",
     "reset_password_sent_at","remember_created_at",
     'created_at', 'updated_at'].each do |col|
      attr.delete col
    end
    attr
  end
  
  def add_related obj
    arr = []
    orgs = Organization.all
    if obj.is_admin?
      arr = orgs.map(&:name)
    else
      # hsh = {:allowed_orignizations=>[]}
      obj.roles.each do |role|
        oid = role.organization_id
        org = orgs.detect{|o| o.id==oid}
        arr << org.name if org
      end
    end
    hash = {:roles => arr}
  end
  
  private

  def _params_
    cols = model_class.columns.map{|a| a.name.to_sym}
    cols = cols | [:roles, :password, :password_confirmation]
    puts "    CCCC #{cols.inspect}"
    ret = params.require(model_name.to_sym).permit(cols)
    ret
  end
  
  def user_params
    params.require(:user).permit(:roles,:firstname, :lastname, :email, :password, :password_confirmation, :is_active)
  end
end