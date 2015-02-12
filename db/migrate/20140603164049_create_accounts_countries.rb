class CreateAccountsCountries < ActiveRecord::Migration
  def up
    create_table :accounts_countries do |t|
      t.integer :account_id
      t.integer :country_id
      t.timestamps
    end
  end
  
  def down
    drop_table :accounts_countries
  end
  
end
