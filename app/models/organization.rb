class Organization < ActiveRecord::Base
	has_many :groups
   has_many :roles
   has_many :accounts
end
