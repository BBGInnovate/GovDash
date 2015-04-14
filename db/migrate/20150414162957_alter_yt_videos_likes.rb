class AlterYtVideosLikes < ActiveRecord::Migration
  def change
    add_column :yt_videos, :dislikes, :integer, default: 0
  end
end
