class RedshiftTwTimeline < Redshift
  self.table_name = "tw_timelines"

  def self.column_array
    ['total_tweets','total_favorites','total_followers','tweets',
           'favorites','followers','retweets','mentions']
  end
end
=begin  
  def RedshiftTwTimeline.copy_from_tw_timelines
    i = 0
    RedshiftTwTimeline.all.each do | fp_old|
      begin
        d=fp_old.tweet_created_at
        fp_new = TwTimeline.where(object_name: fp_old.object_name).
                 where(tweet_created_at: (d.beginning_of_day..d.end_of_day)).
                 to_a.first
        if !fp_new
           new_acc = TwitterAccount.find_by object_name: fp_old.object_name
           fp_new = TwTimeline.create(account_id: new_acc.id,
                     object_name: acc.object_name,
                     tweet_created_at: d.middle_of_day)
          end
          ['total_tweets','total_favorites','total_followers','tweets',
           'favorites','followers','retweets','mentions'].each do |col|
            if fp_new.send(col).to_i < fp_old.send(col).to_i
              val = fp_old.send(col).to_i
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

