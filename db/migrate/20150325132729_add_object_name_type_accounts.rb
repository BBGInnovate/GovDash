class AddObjectNameTypeAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :object_name_type, :string, limit: 40
  end
end
