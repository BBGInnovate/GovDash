class RmTokensAccounts < ActiveRecord::Migration
  def change
    remove_column :accounts, :user_access_token
    remove_column :accounts, :page_access_token
  end
end
