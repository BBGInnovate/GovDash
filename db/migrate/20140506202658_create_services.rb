class CreateServices < ActiveRecord::Migration
  def up
    if Service.table_exists?
       drop_table :services
    end
    create_table :services do |t|
      t.string :name, :limit=>40
      t.string :description
      t.string :network_id
      t.boolean :is_active, :default=>true
      t.timestamps
    end
    Service.populate
  end
  def down
    drop_table :services
  end
end
