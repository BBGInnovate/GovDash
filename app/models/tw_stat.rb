# require Rails.root.to_s + '/lib/read_stat_detail'

class TwStat < StatDetail
  # include ReadStatDetail

  def self.table_class
    REPLICA ? ReplicaTwTimeline : TwTimeline
  end
  def self.created_at
    'tweet_created_at'
  end
  def self.data_columns
    # in database select query:
    # select retweets AS retweets
    {'retweets'=>'retweets','mentions'=>'mentions',
     'favorites'=>'favorites','followers'=>'followers'}
  end

end
