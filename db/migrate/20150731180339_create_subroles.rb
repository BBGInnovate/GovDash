class CreateSubroles < ActiveRecord::Migration
  def change
    create_table :subroles do |t|
      t.string :name
      t.string :description
      t.timestamp
    end
    Subrole.create :name=>'pending',:description=>'No access to the report. waiting for email confirmation'
    Subrole.create :name=>'viewer',:description=>'Only read access'
    Subrole.create :name=>'Group Admin',:description=>"Read/Write the group owned assets"
    Subrole.create :name=>'Organization Admin',:description=>"Read/Write the organization owned assets"
    Subrole.create :name=>'Super Admin',:description=>"Read/Write all assets. The same as user.is_admin"
  
   end
end
