class AlterDescriptionAccountProfiles < ActiveRecord::Migration
  def change
    change_column(:account_profiles, :description, :text)
  end
end
