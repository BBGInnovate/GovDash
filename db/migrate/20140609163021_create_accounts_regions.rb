class CreateAccountsRegions < ActiveRecord::Migration
  def change
    create_table :accounts_regions do |t|
      t.integer :account_id
      t.integer :region_id
      t.timestamps
    end
  end
end
