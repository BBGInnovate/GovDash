class AddOrganizationIdToGroups < ActiveRecord::Migration
  def change
    add_reference :groups, :organization, index: true
    add_foreign_key :groups, :organizations
  end
end
