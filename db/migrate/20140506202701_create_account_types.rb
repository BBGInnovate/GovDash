class CreateAccountTypes < ActiveRecord::Migration
  def up
    create_table :account_types do |t|
      t.string :name, :limit=>20
      t.boolean :is_active, :default=>true
      t.timestamps
    end
    AccountType.populate
  end
  
  def down
    drop_table :account_types
  end
end
