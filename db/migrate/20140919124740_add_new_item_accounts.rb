class AddNewItemAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :new_item, :boolean, :default=>0
  end
end
