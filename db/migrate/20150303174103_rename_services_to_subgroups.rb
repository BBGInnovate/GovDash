class RenameServicesToSubgroups < ActiveRecord::Migration
  def up
    begin
  	rename_table :services, :subgroups
  	remove_column :subgroups, :network_id
    rescue
    end
  end
  def down
    begin
  	rename_table :subgroups, :services
    rescue
    end
  end
end
