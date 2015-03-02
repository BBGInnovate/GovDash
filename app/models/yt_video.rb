class YtVideo < ActiveRecord::Base
  belongs_to :channel, foreign_key: :channel_id
end
