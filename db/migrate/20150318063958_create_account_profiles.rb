class CreateAccountProfiles < ActiveRecord::Migration
  def change
    create_table :account_profiles do |t|
      t.integer :account_id
      t.string :platform_type, :limit=>20
      t.string :name, :limit=>40
      t.string :display_name, :limit=>40
      t.string :description
      t.string :location
      t.string :url
      t.string :avatar
      t.integer :total_followers
      t.boolean :verified
      
      t.timestamps
    end
  end
end
 