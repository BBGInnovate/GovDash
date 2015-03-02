class CreateYtChannels < ActiveRecord::Migration
  def change
    create_table :yt_channels do |t|
      t.integer :account_id
      t.string :channel_id
      t.integer :views
      t.integer :comments
      t.integer :videos
      t.integer :subscribers
      t.datetime :published_at # store latest video published_at for retrieval
      t.timestamps
    end
    add_index :yt_channels, :published_at
    add_index :yt_channels, :account_id
    add_index :yt_channels, :channel_id
  end
end
