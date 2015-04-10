class RedshiftTwTweet < Redshift
  self.table_name = "tw_tweets"

  def self.column_array
    ['favorites','retweets','mentions']
  end
end
=begin  
  def RedshiftTwTweet.copy_from_tw_tweet
    old_acc_ids = RedshiftTwTimeline.select("distinct account_id").to_a
    old_acc_ids.each do | old_acc_id |
      obj_name = RedshiftTwTimeline.find_by(account_id: old_acc_id).object_name
      new_acc = TwitterAccount.find_by object_name: obj_name
      RedshiftTwTweet.where(account_id: old_acc_id).to_a.each do |fp_old|
        begin
          d=fp_old.tweet_created_at
          fp_new = TwTweet.find_by(tweet_id: fp_old.tweet_id).first
          if !fp_new
             fp_new = TwTweet.create(account_id: new_acc.id,
                  tweet_id: fp_old.tweet_id)
          end
          ['favorites','retweets','mentions'].each do |col|
            if fp_new.send(col).to_i < fp_old.send(col).to_i
              val = fp_old.send(col)
              fp_new.send("#{col}=", val)
            end
            fp_new.tweet_created_at = fp_old.tweet_created_at
            fp_new.save
          end
        rescue exception=>ex
          logger.error "  Fbpage.copy_from_fb_pages #{ex.message}"
        end
      end
    end
  end
=end
