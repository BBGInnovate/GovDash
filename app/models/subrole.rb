class Subrole < ActiveRecord::Base
   has_many :users

   def self.pending_id
     find_by(name: "Pending").id
   end
   def self.viewer_id
     find_by(name: "Viewer").id
   end
   def self.group_admin_id
     find_by(name: "Group Admin").id
   end
   def self.organization_admin_id
     find_by(name: "Organization Admin").id
   end
   def self.super_admin_id
     find_by(name: "Super Admin").id
   end
end