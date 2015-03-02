class RenameNetworkToGroup < ActiveRecord::Migration
  def change
  	rename_table :networks, :groups
  end
end
