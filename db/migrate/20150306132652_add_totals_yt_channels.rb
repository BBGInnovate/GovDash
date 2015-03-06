class AddTotalsYtChannels < ActiveRecord::Migration
  def change
    add_column :yt_channels, :total_views, :integer, after: :subscribers, default: 0
    add_column :yt_channels, :total_likes, :integer, after: :subscribers, default: 0
    add_column :yt_channels, :total_favorites, :integer, after: :subscribers, default: 0
    add_column :yt_channels, :total_comments, :integer, after: :subscribers, default: 0
  end
end
