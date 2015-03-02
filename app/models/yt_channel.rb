class YtChannel < ActiveRecord::Base
  belongs_to :account
  has_many :yt_videos, foreign_key: :channel_id

end
