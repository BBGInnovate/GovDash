class CreateSubgroupsRegions < ActiveRecord::Migration
  def change
    unless connection.table_exists? 'subgroups_regions'
    create_table :subgroups_regions do |t|
      t.integer :subgroup_id
      t.integer :region_id
      t.timestamp
    end
    end
  end
end
