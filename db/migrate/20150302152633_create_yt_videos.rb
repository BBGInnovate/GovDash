class CreateYtVideos < ActiveRecord::Migration
  def change
    # likes = like_count - dislike_count
    create_table :yt_videos do |t|
      t.integer :account_id
      t.string :channel_id
      t.string :video_id, :limit=>40
      t.integer :likes
      t.integer :comments
      t.integer :favorites
      t.datetime :published_at
      t.timestamps
    end
    add_index :yt_videos, :account_id
    add_index :yt_videos, :channel_id
    add_index :yt_videos, :video_id,:unique=>true
    add_index :yt_videos, :published_at
  end
end
