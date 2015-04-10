class CreateSubgroupsRegions < ActiveRecord::Migration
  def change
    create_table :subgroups_regions do |t|
      t.integer :subgroup_id
      t.integer :region_id
      t.timestamp
    end
  end
end
