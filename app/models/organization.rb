class Organization < ActiveRecord::Base
	has_many :groups
   has_many :roles
   has_many :accounts
   
  default_scope { where(is_active: true) }
end
