class CreateAccountsScSegmentsJoinTable < ActiveRecord::Migration
  def self.up
    create_table :accounts_sc_segments, :id => false do |t|
      t.integer :sc_segment_id
      t.integer :account_id
    end

    add_index :accounts_sc_segments, [:sc_segment_id, :account_id]
  end

  def self.down
    drop_table :accounts_sc_segments
  end
end
