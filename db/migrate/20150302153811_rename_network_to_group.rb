class RenameNetworkToGroup < ActiveRecord::Migration
  def change
    begin
  	   rename_table :networks, :groups
  	 rescue Exception=>ex
  	   Rails.logger.error " RenameNetworkToGroup #{ex.message}"
  	 end
  end
end
