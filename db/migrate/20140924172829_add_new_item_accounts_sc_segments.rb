class AddNewItemAccountsScSegments < ActiveRecord::Migration
  def change
    add_column :accounts_sc_segments, :new_item, :boolean, :default=>0
  end
end
