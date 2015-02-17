require 'ostruct'
class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  validates :password, length: { in: 6..128 }, on: :create
  validates :password, length: { in: 6..128 }, on: :update, allow_blank: true
  
  belongs_to :role
  has_and_belongs_to_many :accounts
  
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
  
  def merge_role
    user = OpenStruct.new(self.attributes)
    if self.role_id
      user.role = OpenStruct.new(self.role.attributes) 
    else
      user.role = OpenStruct.new :name=>'Nobody'
    end
    user.role = user.role.send 'table'
    user
  end
  
  def is_admin?
    self.role && self.role.name == 'Administrator'
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
