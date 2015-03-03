class CreateJoinTableGroupSubgroup < ActiveRecord::Migration
  def change
    create_join_table :groups, :subgroups do |t|
      # t.index [:group_id, :subgroup_id]
      # t.index [:subgroup_id, :group_id]
    end
  end
end
