class RenameServicesToSubgroups < ActiveRecord::Migration
  def up
  	rename_table :services, :subgroups
  	remove_column :subgroups, :network_id
  end
  def down
  	rename_table :subgroups, :services
  end
end
