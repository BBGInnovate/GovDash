class RecreateYtVideos < ActiveRecord::Migration
  def up
    if ActiveRecord::Base.connection.table_exists? 'yt_videos'
      drop_table :yt_videos
    end
    create_table :yt_videos do |t|
      t.integer :account_id
      t.string :video_id, :limit=>40
      t.integer :likes
      t.integer :comments
      t.integer :favorites
      t.datetime :published_at
      t.timestamps
    end
    add_index :yt_videos, :account_id
    add_index :yt_videos, :video_id, :unique=>true
    add_index :yt_videos, :published_at
  end
  
  def down
    remove_index :yt_videos, :account_id
    remove_index :yt_videos, :video_id
    remove_index :yt_videos, :published_at
    drop_table :yt_videos
  end
  
end
