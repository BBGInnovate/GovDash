class AlterNameGroups < ActiveRecord::Migration
  def up
      change_column(:groups, :name, :string, limit: 100)
      change_column(:subgroups, :name, :string, limit: 100)
      change_column(:account_types, :name, :string, limit: 40)
  end
  
  def down
      change_column(:groups, :name, :string, limit: 40)
      change_column(:subgroups, :name, :string, limit: 40)
      change_column(:account_types, :name, :string, limit: 20)
  end
  
end
