# require Rails.root.to_s + '/lib/read_stat_detail'

class YtStat < StatDetail
  # include ReadStatDetail

  def self.table_class
    YtChannel
  end
  def self.created_at
    'published_at'
  end
  def self.data_columns
    {'video_subscribers'=>'subscribers',
     'video_likes'=>'likes',
     'video_comments'=>'comments',
     'video_favorites'=>'favorites'}
  end

end


