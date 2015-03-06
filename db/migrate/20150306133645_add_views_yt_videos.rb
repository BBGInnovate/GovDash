class AddViewsYtVideos < ActiveRecord::Migration
  def change
    add_column :yt_videos, :views, :integer, after: :favorites, default: 0
  end
end
