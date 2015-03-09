class YtChannel < ActiveRecord::Base
  belongs_to :youtube_account, foreign_key: :account_id
  
  after_save :sync_redshift
   
  def yt_videos
    @yt_videos ||= 
       YtVideo.where("account_id = #{self.account_id}").to_a
  end
  
  def sync_redshift
    attr = self.attributes
    RedshiftYtChannel.create_or_update(attr)
  end
  # bin/delayed_job restart 
  # to clear cache of method create_or_update
  handle_asynchronously :sync_redshift, :run_at => Proc.new { 5.seconds.from_now }
  
  def self.update_video_subscribers
    YoutubeAccount.all do | acc |
      arr = acc.yt_channels.order(:published_at)
      arr.each do | ch |
        pre_day = ch.published_at - 1.day
        pre_ch = self.where("publised_at = '#{pre_day}'").last
        if pre_ch
          ch.video_subscribers = ch.subscribers.to_i - pre_ch.subscribers.to_i
          ch.save
        end  
      end
    end
  end
  
end
