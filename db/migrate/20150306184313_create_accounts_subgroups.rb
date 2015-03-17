class CreateAccountsSubgroups < ActiveRecord::Migration
  def change
    create_join_table :accounts, :subgroups do |t|
      # t.index [:acount_id, :subgroup_id]
      # t.index [:subgroup_id, :acount_id]
    end
  end
end
