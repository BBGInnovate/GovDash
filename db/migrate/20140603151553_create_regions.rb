class CreateRegions < ActiveRecord::Migration
  def up
    create_table :regions do |t|
      t.string :name, :limit=>30
      t.boolean :is_active, :default=>true
    end
    Region.populate
    #Region.send 'populate_market'
  end
  
  def down
    drop_table :regions 
  end
  
end
