class AddIsActiveOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :is_active,:boolean, default: true
  end
end
