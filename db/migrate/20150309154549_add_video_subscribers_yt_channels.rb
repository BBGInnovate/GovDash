class AddVideoSubscribersYtChannels < ActiveRecord::Migration
  def up
    add_column :yt_channels, :video_subscribers, :integer, after: :subscribers, default: 0
    # YtChannel.update_video_subscribers
  end
  
  def down
    remove_column :yt_channels, :video_subscribers
  end
  
end
