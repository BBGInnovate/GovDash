class RemoveGroupIdAndServiceIdColumnsFromAccounts < ActiveRecord::Migration
  def up
  	remove_column :accounts, :group_id
  	remove_column :accounts, :service_id
  end
  def down
  	add_column :accounts, :group_id
  	add_column :accounts, :service_id
  end
end
