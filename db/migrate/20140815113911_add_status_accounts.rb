class AddStatusAccounts < ActiveRecord::Migration
  def up
    unless Account.connection.column_exists?('accounts','status')
      add_column "accounts",:status, :boolean,:default=>true,:after=> :object_name
    end
  end
  def down
    if Account.connection.column_exists?('accounts','status')
      remove_column "accounts",:status
    end
  end
end
