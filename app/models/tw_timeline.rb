class TwTimeline < ActiveRecord::Base
  # after_save :sync_redshift
  
  belongs_to :account, :foreign_key=>:account_id
  
  def sync_redshift
    attr = self.attributes
    RedshiftTwTimeline.create_or_update(attr)
  end
  # bin/delayed_job restart 
  # to clear cache of method create_or_update
  handle_asynchronously :sync_redshift, :run_at => Proc.new { 5.seconds.from_now }
  
end
