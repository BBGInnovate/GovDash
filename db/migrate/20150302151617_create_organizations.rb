class CreateOrganizations < ActiveRecord::Migration
  def change
    unless connection.table_exists? 'organizations'
      create_table :organizations do |t|
        t.string :name      
        t.timestamps null: false
      end
    end
  end
end


