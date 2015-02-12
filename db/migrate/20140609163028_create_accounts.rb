class CreateAccounts < ActiveRecord::Migration
  def up
    if Account.table_exists?
       drop_table :accounts
    end
    create_table :accounts do |t|
      t.string :name, :limit=>40
      t.string :description
      t.string :object_name, :limit=>40  # e.g.  voiceofamerica
      t.boolean :page_admin, :default=>false  # if my FB APP is Admin for this FB page, required by FB InSights 
      t.string :media_type_name, :default=>"FacebookAccount", :limit=>20
      t.integer :network_id
      t.integer :service_id
      t.integer :account_type_id
      t.integer :language_id
      t.string :contact
      t.string :client_id,:limit=>64
      t.string :client_secret, :limit=>64
      t.string :canvas_url
      t.string :user_access_token
      t.string :page_access_token
      t.boolean :is_active, :default=>true
      t.timestamps
    end
    FacebookAccount.populate
    TwitterAccount.populate
  end

  def down
    drop_table :accounts
  end
  
end
