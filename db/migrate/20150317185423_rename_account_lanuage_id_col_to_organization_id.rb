class RenameAccountLanuageIdColToOrganizationId < ActiveRecord::Migration
  def self.up
    rename_column :accounts, :language_id, :organization_id
  end
  
  def self.down
    rename_column :accounts, :organization_id, :language_id
  end
  
end
