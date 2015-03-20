class ChangeDescriptionAccountProfiles < ActiveRecord::Migration
  def change
    change_column(:account_profiles, :description, :text)
  end
end
