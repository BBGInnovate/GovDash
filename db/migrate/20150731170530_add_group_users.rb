class AddGroupUsers < ActiveRecord::Migration
  def change
    add_column :users, :confirmation_code, :string, :limit=>40
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :group_id, :integer
    add_column :users, :subrole_id, :integer
  end
end
