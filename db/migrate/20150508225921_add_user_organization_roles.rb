class AddUserOrganizationRoles < ActiveRecord::Migration
  def up
    add_column :roles, :user_id, :integer
    add_column :roles, :organization_id, :integer
    # remove_column :users, :role_id
  end
  
  def down
    remove_column :roles, :user_id 
    remove_column :roles, :organization_id
    # add_column :users, :role_id, :integer
  end
  
end
