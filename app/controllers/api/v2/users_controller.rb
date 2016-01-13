require 'ostruct'
class Api::V2::UsersController < Api::V2::BaseController
  before_filter :authenticate_user!, :except => [:timeout,:confirm,:create, :show, :forget_password,:reset_password]
  skip_before_filter :is_admin?,:only => [:create, :show]  
  skip_after_filter :update_session, :only => [:timeout]
  
  def roles
    render :json => {:roles => User.roles}, :status => 200
  end

  def index
    arr = []
    model_class.all.each do |s|
      row = add_associate_name(s)
      row = modify_row s, row
      arr << row
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
    id = params[:id]
    if id.size == 64
      record = model_class.find_by reset_password_token: params[:id]
    else
      record = model_class.find(params[:id])
    end
    arr << add_associate_name(record)
    arr[0] = modify_row record, arr[0]
    pretty_respond arr
  end
  
  # /api/users/5/check_timeout
  def timeout
    user = User.find_by id: (params[:user_id] || params[:id])
    dura = (Time.zone.now - user.updated_at).to_i
    message = 'Session OK'
    if user.timedout?(dura.seconds.ago)
      message = 'Session expired'
    else
      (1..10).each do | mm |
        if user.timeout_in.to_i - (dura + mm.minutes) < 0
          message = 'Session expires in #{mm} minutes'
          break
        end
      end
    end
    render json: {:status => 200, :user_id=>user.id, :message =>message},
        :status => 200
    # user.timedout?( dura.to_i.seconds.ago - 5.minutes)
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
    begin
      uri = URI.parse request.original_url
      port =  uri.port == 80 ? "" : ":#{uri.port}"  
      host = "#{uri.scheme}://#{uri.host}#{port}"
      production = uri.host.match(/bbg\.gov/)
      pars = _params_
      @roles = pars.delete 'roles'
      @email = pars[:email]
      # @user = User.find_by email: @email
      @user = User.new # if !@user
      pars.each_pair do | key, val |
        if @user.respond_to?(key) && val
          @user.send("#{key}=", val)
        end
      end
      if @user.valid?
        if !email_valid?(@email)
          logger.debug "Email not valid"
          raise "Email is not valid"
        end
        @user.confirmation_code = @user.generate_confirmation_code
        @user.request_host = host
        msg = @user.send_confirmation_email
        if msg.to_s.match(/^Error:/)
          raise msg
        end
        @user.confirmation_sent_at = Time.zone.now
        @user.save
        if @roles
          reset_roles @user, @roles
        end
        ## sign_in(@user)
        ## respond_with @user, :location => api_users_path
        # params[:id] = @user.id
        # show
        logger.info "Email confirmation sent"
        render json: {:status => 'OK', :message => "Email confirmation sent"}
      else
        logger.info @user.errors.full_messages.join(', ')
        render json: {:status => 200, :message => @user.errors.full_messages.first},
           :status => 200
      end
    rescue Exception=>ex
      logger.info ex.message
      render json: {:status => 'failed', :message => ex.message}
      # respond_with @user.errors, :location => new_user_registration_path
    end
  end

  def update
    # user_id = params.delete(:id)
    @roles = params[:user].delete 'roles'
    u = User.find params[:id]
    if u
      mypar = _params_
      if mypar[:password]
        u.reset_password_token = nil if u.reset_password_token
        u.reset_password_sent_at = nil if u.reset_password_sent_at
      end
      u.update_attributes( mypar )
      reset_roles u, @roles
      if Organization.all.size > u.roles.size
        # u.is_admin = false if u.is_admin
        u.subrole_id = 4 if u.subrole_id == 5
        u.save
      end
    else
      u="User not found"
    end
    show
    # respond_with :api, u
  end

  def destroy
    if current_user && current_user.is_admin?
      respond_with :api, User.find(params[:id]).destroy
    else
      respond_with :api, 'Not permitted'
    end
  end

  def email_valid? email
    # EmailVerifier.check(email)
    domain_name = email.split('@').last
    mail_servers = Resolv::DNS.open.getresources(domain_name, Resolv::DNS::Resource::IN::MX)
    !mail_servers.empty?
  end

  def confirm
    begin
      user = User.find_by :confirmation_code=>params[:code]
      num = Rails.configuration.new_user_confirmation_expires_in
      if Time.zone.now <= user.confirmation_sent_at + num.hours
        user.subrole_id = Subrole.viewer_id
        user.save!
        flash[:notice]="Your email is confirmed"
      else
        flash[:error] = "Confirmation link expired"
        logger.error "  UsersController#confirm: Confirmation expired"
      end
      redirect_to root_path
     
    rescue Exception=>ex
      flash[:error] = "Confirmation failed"
      logger.error "  UsersController#confirm: #{ex.message}"
      redirect_to root_path
    end
  end

  def forget_password
    @user = User.find_by email: params[:email]
    status = 200
    if @user
      message = "New password sent to #{@user.email}"
      status = 200
      new_pass = @user.generate_confirmation_code
      @user.password = new_pass
      @user.password_confirmation = new_pass
      p " @user.valid? = #{@user.valid?}"
      if @user.valid?
        msg = @user.send_forget_password_email(new_pass)
        if msg.to_s.match(/^Error:/)
          message = msg
        else
          @user.reset_password_token = new_pass
          @user.reset_password_sent_at = Time.zone.now
          @user.save
          status = 200
        end
      else
        message = @user.errors.full_messages.first
      end
    end
    render json: {:status => status, :message => message},
      :status => status
  end
  
  protected
 
  def modify_row user, row
    row.delete 'confirmation_code'
    row.delete 'confirmation_sent_at'
    if user.organization
      row.delete 'organization_id'
      row['organization_id']=user.organization.id
      row['organization_name']=user.organization.name
    end
    if user.group
      row.delete 'group_id'
      row['group_id']=user.group.id
      row['group_name']=user.group.name
    end
    if user.subrole
      row.delete 'subrole_id'
      row['subrole_id']=user.subrole.id
      row['subrole_name']=user.subrole.name
    end
    return row

    perm = user.get_permissions
    row[:full_access] = {:organizations=>perm[:organization],
     :groups=>perm[:group],
     :subgroups=>perm[:subgroup],
     :accounts =>  perm[:account]}
    row
  end

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
    # if obj.is_admin?
    #  arr = orgs.map(&:name)
    # else
      # hsh = {:allowed_orignizations=>[]}
      obj.roles.each do |role|
        oid = role.organization_id
        org = orgs.detect{|o| o.id==oid}
        arr << org.name if org
      end
    # end
    hash = {:roles => arr}
  end
  
  private

  def _params_
    cols = model_class.columns.map{|a| a.name.to_sym}
    cols = cols | [:roles, :password, :password_confirmation]
    ret = params.require(model_name.to_sym).permit(cols)
    ret
  end
  
  def user_params
    params.require(:user).permit(:roles,:firstname, :lastname, :email, :password, :password_confirmation, :is_active)
  end
end
