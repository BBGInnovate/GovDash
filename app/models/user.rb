require 'ostruct'
class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  attr_accessor :request_host
  # roles list organizations a user can manager
  has_many :roles
  # subrole specifies a user's read/write permissions 
  # if sunrole_id == 3, user can read/write to the group he belongs_to
  # if sunrole_id == 4, user can read/write to the org he belongs_to
  belongs_to :subrole
  has_and_belongs_to_many :accounts
  belongs_to :group
  belongs_to :organization

  after_save :update_organization
  before_save :update_group

  def update_group
    grp = find_default_group
    if grp
      self.group_id = grp.id
    end
  end
  
  def update_organization
    og = find_defaul_organization
    hsh = {}
    if og
      self.roles.find_or_create_by organization_id: og.id
      self.roles.update_all :name => self.email
      if self.roles.count == Organization.count
        hsh['is_admin'] = true
      end
      if self.respond_to? :organization_id
        hsh['organization_id'] = og.id
      end
    end
    if self.is_admin
      hsh['subrole_id'] = Subrole.super_admin_id
    end
    unless hsh.blank?
      self.update_columns hsh
    end
  end

  def find_default_group
    self.email.match(/@(\w+\.gov|\w+\.com|\w+\.mil|\w+\.org)/)
    name = ''
    n = $1
    case n
    when 'state.gov','america.gov'
    when 'voanews.com','bbg.gov'
      name = 'VOA'
    when 'rferl.org'
      name = 'RFERL'
    when 'martinoticias.com'
      name = 'OCB'
    when 'alhurra.com','radiosawa.com'
      name = 'MBN'
    when 'rfa.org'
      name = 'RFA'
    end
    grp = Group.find_by name: name
  end
  
  def find_defaul_organization
    self.email.match(/@(\w+\.gov|\w+\.com|\w+\.mil|\w+\.org)/)
    n = $1
    orn = ''
    case n
    when 'state.gov','america.gov'
      orn = 'dos'
    when 'bbg.gov','voanews.com','rferl.org','martinoticias.com'
      orn = 'bbg'
    when 'alhurra.com','radiosawa.com','rfa.org'
      orn = 'bbg'
    when 'cttso.gov'
      orn = 'dod'
    else
      if n.match /\.mil$/
        orn = 'dod'
      end
    end
    Organization.find_by name: orn
  end

  def to_label
    'User'
  end
  
  def name
    n = "#{firstname} #{lastname}"
    if n.strip.empty?
      n = 'No name given'
    end
  end
  def name=(fullname)
    arr=fullname.split(' ')
    update_attibutes :firstname=>arr[0], :lastname=>arr[1]
  end
  
  def organizations
    self.roles.map(&:organization)
  end
  
  def merge_role
    user = OpenStruct.new(self.attributes)
    attr = []
    orgs = self.roles.map(&:organization).map(&:name)
    if !orgs.empty?
      org_names = orgs.join(',')
    else
      org_names = 'Nobody'
    end
    # role={:name=>"bbg,dos"}
    user.role = OpenStruct.new :name=>org_names
=begin
    if self.role_id
      user.role = OpenStruct.new(attr) 
    elsif self.is_admin
      user.role = OpenStruct.new(self.roles.attributes)
    else
      user.role = OpenStruct.new :name=>'Nobody'
    end
=end
    user.role = user.role.send 'table'
    user
  end
  
  def is_admin?
    is_admin || (self.subrole ? self.subrole_id==Subrole.super_admin_id : false)
  end
  
=begin
  def is_analyst?
     self.role && self.role.name == 'Analyst'
  end
  
  def is_service_chief?
     self.role && self.role.name == 'Service Chief'
  end
=end

  def self.roles
    re = []
    Role.all.each do |r|
      re << {"name"=>r.name, "id"=>r.id}
    end
    re
  end

  def get_permissions
    return @hash if !@hash.blank?
    @hash = {:group=>[],:subgroup=>[],:account=>[],
      :organization=>[]}
    if self.is_admin?
      @hash[:account] = []
      @hash[:organization]=[]
      @hash[:group] = []
      @hash[:subgroup]=[]
      Organization.all.each do |org|
        @hash[:organization] << org.id
        @hash[:account] << org.accounts.map(&:id)
        group = org.groups.map(&:id)
        @hash[:group] << group
        @hash[:subgroup] << GroupsSubgroups.where(["group_id in (?)", group]).
                      map(&:subgroup_id)
      end
      @hash[:account].flatten!
      @hash[:group].flatten!
      @hash[:subgroup].flatten!
    else
      if self.subrole_id && self.subrole_id > 2
        if self.subrole.name == 'Group Admin' 
          @hash[:group] = [self.group_id]
          group = Group.find self.group_id
          @hash[:account] = group.accounts.map(&:id)
          @hash[:subgroup]  = GroupsSubgroups.where("group_id = #{self.group_id}").
                    map(&:subgroup_id)
          @hash[:organization] = [self.organization.id]
        elsif self.subrole.name == 'Organization Admin' &&
          self.organization && self.organization.groups.size > 1
          @hash[:account] = self.organization.accounts.map(&:id)
          @hash[:group] = self.organization.groups.map(&:id)
          @hash[:subgroup] = GroupsSubgroups.where(["group_id in (?)", @hash[:group]]).
                      map(&:subgroup_id)
          @hash[:organization] = [self.organization.id]
        end
      end
    end
    @hash
  end

  def send_confirmation_email
    begin
      UserMailer.confirm_email(self).deliver_now!
    rescue Net::SMTPFatalError=>ex
      "Error: #{ex.message}"
    end
  end

  def send_forget_password_email new_pass
    begin
      UserMailer.forget_password_email(self, new_pass).deliver_now!
    rescue Net::SMTPFatalError=>ex
      "Error: #{ex.message}"
    end
  end
  
  def generate_confirmation_code
    rand(36**24).to_s(36)
  end

  def password_required?
     !persisted? || password.present? || password_confirmation.present?
  end
  
end
