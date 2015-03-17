class CreateAccountsGroups < ActiveRecord::Migration
  def change
    create_join_table :accounts, :groups do |t|
      # t.index [:acount_id, :group_id]
      # t.index [:group_id, :acount_id]
    end
  end
end
