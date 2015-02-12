class CreateScSegments < ActiveRecord::Migration
  def change
    create_table :sc_segments do |t|
      t.string :name
      t.string :sc_id
      t.timestamps
    end
  end
end
