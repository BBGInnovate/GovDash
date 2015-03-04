class AddOrganizationIdToGroups < ActiveRecord::Migration
  def change
    begin
      add_reference :groups, :organization, index: true
      add_foreign_key :groups, :organizations
    rescue Exception=>ex
  	   Rails.logger.error " AddOrganizationIdToGroups #{ex.message}"
  	 end
  end
end
