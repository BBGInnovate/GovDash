class CreateLanguages < ActiveRecord::Migration
  def up
    if Language.table_exists?
       drop_table :languages
    end
    create_table :languages do |t|
      t.string :name,:limit=>30
      t.string :iso_639_1, :limit=>6
      t.boolean :is_active, :default=>true
    end
    Language.populate
  end
  
  def down
    drop_table :languages
  end
  
end
