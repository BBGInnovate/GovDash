class CreateRoles < ActiveRecord::Migration
  def up
    create_table :roles do |t|
      t.string :name
      t.string :description
      t.boolean :is_active, :default=>true
      t.integer :weight
      t.timestamps
    end
    Role.populate
  end
  
  def down
    drop_table :roles
  end
end
