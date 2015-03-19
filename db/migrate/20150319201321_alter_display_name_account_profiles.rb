class AlterDisplayNameAccountProfiles < ActiveRecord::Migration
  def change
    change_column(:account_profiles, :display_name, :string, :limit=>255)
  end
end
