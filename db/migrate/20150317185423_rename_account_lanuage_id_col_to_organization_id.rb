class RenameAccountLanuageIdColToOrganizationId < ActiveRecord::Migration
  def self.up
    rename_column :accounts, :language_id, :organization_id
  end
end
