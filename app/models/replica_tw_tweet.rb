class ReplicaTwTweet < Replica
  self.table_name = "tw_tweets"

class << self 
  def column_array
    ['favorites','retweets','mentions']
  end
  
  def date_array
    ['tweet_created_at']
  end
end
end

