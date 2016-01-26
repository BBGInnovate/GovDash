class TwTweet < ActiveRecord::Base

  belongs_to :account, :foreign_key=>:account_id
  # after_save :sync_redshift
  
  def sync_redshift
    attr = self.attributes
    RedshiftTwTweet.create_or_update(attr)
  end
  # bin/delayed_job restart 
  # to clear cache of method create_or_update
  handle_asynchronously :sync_redshift, :run_at => Proc.new { 5.seconds.from_now }
  
  def self.delete_duplicates
    dups = TwTweet.select("account_id, tweet_id, count(*) as cont").
       group([:account_id,:tweet_id]).having("cont > 1").to_a  
    dups.each do | du |
      sql = "delete from tw_tweets where tweet_id = #{du.tweet_id} limit #{du.cont-1}"
      ActiveRecord::Base.connection.send(:delete_sql, sql)
    end
  end
end
