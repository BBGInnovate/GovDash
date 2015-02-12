class CreateTwitterUsers < ActiveRecord::Migration
  def up
    create_table :twitter_users do |t|
      t.string :identifier, :limit => 20
      t.string :access_token
      t.string :access_token_secret
      t.text :access_token_obj
      t.timestamps
    end
  end
  
  def down
    drop_table :twitter_users
  end
  
end
