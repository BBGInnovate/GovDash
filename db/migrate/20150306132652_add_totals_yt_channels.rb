class AddTotalsYtChannels < ActiveRecord::Migration
  def change
    add_column :yt_channels, :video_views, :integer, after: :subscribers, default: 0
    add_column :yt_channels, :video_likes, :integer, after: :subscribers, default: 0
    add_column :yt_channels, :video_favorites, :integer, after: :subscribers, default: 0
    add_column :yt_channels, :video_comments, :integer, after: :subscribers, default: 0
  end
end
