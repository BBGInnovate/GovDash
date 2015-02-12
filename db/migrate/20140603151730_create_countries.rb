class CreateCountries < ActiveRecord::Migration
  def up
    create_table :countries do |t|
      t.string :name, :limit=>60
      t.string :code, :limit=>4
      t.boolean :is_active, :default=>true
      t.integer :region_id
    end
    Country.populate
  end
  
  def down
    drop_table :countries
  end
  
  
end
