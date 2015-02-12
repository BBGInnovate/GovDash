class CreateAccountsUsers < ActiveRecord::Migration
  def up
    if AccountsUser.table_exists?
       drop_table :accounts_users
    end
    create_table :accounts_users do |t|
      t.integer :account_id
      t.integer :user_id
      t.timestamps
    end
  end
  
  def down
    drop_table :accounts_users
  end
  
end
