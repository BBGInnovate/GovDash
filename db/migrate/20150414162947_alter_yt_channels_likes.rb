class AlterYtChannelsLikes < ActiveRecord::Migration
  def change
    add_column :yt_channels, :video_dislikes, :integer, default: 0
  end
end
