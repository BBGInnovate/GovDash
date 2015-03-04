class YtVideo < ActiveRecord::Base
  belongs_to :youtube_account, foreign_key: :account_id
  
  after_save :sync_redshift
  
  def sync_redshift
    attr = self.attributes
    RedshiftYtVideo.create_or_update(attr)
  end
  # bin/delayed_job restart 
  # to clear cache of method create_or_update
  handle_asynchronously :sync_redshift, :run_at => Proc.new { 5.seconds.from_now }
  
  def yt_channel
    YtChannel.order("id desc").find_by account_id: self.account_id
  end
  
end
