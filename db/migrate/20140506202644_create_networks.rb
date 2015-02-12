class CreateNetworks < ActiveRecord::Migration
  def up
    create_table :networks do |t|
      t.string :name, :limit=>10
      t.string :description
      t.boolean :is_active, :default=>true
      t.timestamps
    end
    Network.populate
  end
  def down
    drop_table :networks
  end
end
