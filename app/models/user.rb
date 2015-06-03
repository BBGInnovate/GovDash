require 'ostruct'
class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  validates :password, length: { in: 6..128 }, on: :create
  validates :password, length: { in: 6..128 }, on: :update, allow_blank: true
  
  has_many :roles
  has_and_belongs_to_many :accounts
  belongs_to :organization
  
  after_save :update_organization
  
  def update_organization
    if self.email.match(/@(\w+\.gov|\w+\.com|\w+\.mil|\w+\.org)/)
      n = $1
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
      og = Organization.find_by name: orn
      if og
        self.roles.find_or_create_by organization_id: og.id
        self.roles.update_all :name => self.email
      end
    end
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
    is_admin
    # self.role && self.role.name == 'Administrator'
  end
  
  def is_analyst?
     self.role && self.role.name == 'Analyst'
  end
  
  def is_service_chief?
     self.role && self.role.name == 'Service Chief'
  end

  def self.roles
    re = []
    Role.all.each do |r|
      re << {"name"=>r.name, "id"=>r.id}
    end
    re
  end
  
  def password_required?
     !persisted? || password.present? || password_confirmation.present?
  end
  
end
