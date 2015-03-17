class RenameNetworkIdColumnInAccounts < ActiveRecord::Migration
  def self.up
  	 #change foreign_key to group_id
  	 begin
      rename_column :accounts, :network_id, :group_id
      add_index :accounts, :group_id
    rescue Exception=>ex
  	   Rails.logger.error " RenameNetworkIdColumnInAccounts #{ex.message}"
  	 end
  end

  def self.down
    rename_column :accounts, :group_id, :network_id
  end
end
