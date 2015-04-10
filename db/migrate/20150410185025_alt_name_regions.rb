class AltNameRegions < ActiveRecord::Migration
  def change
     change_column(:regions, :name, :string, limit: 100)
  end
end
