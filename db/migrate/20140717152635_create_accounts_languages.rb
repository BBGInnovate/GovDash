class CreateAccountsLanguages < ActiveRecord::Migration
  def up
    unless ActiveRecord::Base.connection.table_exists? 'accounts_languages'
      create_table :accounts_languages do |t|
        t.integer :account_id
        t.integer :language_id
        t.timestamps
      end
    end
    
    AccountsLanguage.populate
    
  end
  
  def down
    drop_table :accounts_languages
  end
  
end
