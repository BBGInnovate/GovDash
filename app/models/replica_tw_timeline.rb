class ReplicaTwTimeline < Replica
  self.table_name = "tw_timelines"
class << self 
  def column_array
    ['total_tweets','total_favorites','total_followers','tweets',
           'favorites','followers','retweets','mentions']
  end
  def date_array
    []
  end
end
end


