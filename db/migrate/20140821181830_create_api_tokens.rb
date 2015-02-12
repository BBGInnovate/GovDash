class CreateApiTokens < ActiveRecord::Migration
  def up
    
    unless ActiveRecord::Base.connection.table_exists? 'api_tokens'
      create_table :api_tokens do |t| 
        t.string :platform, :limit=>20
        t.integer :account_id
        t.string :canvas_url
        t.string :api_user_email, :limit=>40
        # t.string :client_id, :limit=>20
        # t.string :client_secret,:limit=>40
        t.string :user_access_token
        t.string :page_access_token
        t.timestamps
      end
    end
    ApiToken.populate
  end
  
  def down
    drop_table :api_tokens
  end
  
end
