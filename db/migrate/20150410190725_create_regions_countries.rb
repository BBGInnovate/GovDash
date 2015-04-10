class CreateRegionsCountries < ActiveRecord::Migration
  def change
    create_table :regions_countries do |t|
      t.integer :region_id
      t.integer :country_id
      t.timestamp
    end
  end
end
