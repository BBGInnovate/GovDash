class CreateMediaTypes < ActiveRecord::Migration
  def up
    create_table :media_types do |t|
      t.string :name, :limit=>20
      t.boolean :is_active,:default=>true
      t.timestamps
    end
    MediaType.populate
  end
  
  def down
    drop_table :media_types
  end
end
