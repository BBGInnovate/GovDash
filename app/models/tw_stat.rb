# require Rails.root.to_s + '/lib/read_stat_detail'

class TwStat < StatDetail
  # include ReadStatDetail

  def self.table_class
    TwTimeline
  end
  def self.created_at
    'tweet_created_at'
  end
  def self.data_columns
    {'retweets'=>'retweets','mentions'=>'mentions',
     'favorites'=>'favorites','followers'=>'followers'}
  end

end
