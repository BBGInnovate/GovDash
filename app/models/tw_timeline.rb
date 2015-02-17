# require Rails.root.to_s + '/lib/read_page_detail'

class TwTimeline < ActiveRecord::Base
#  include ReadPageDetail
  
  # belongs_to :account

  after_save :sync_redshift
  def sync_redshift
    attr = self.attributes
    RedshiftTwTimeline.create_or_update(attr)
  end
  # bin/delayed_job restart 
  # to clear cache of method create_or_update
  handle_asynchronously :sync_redshift, :run_at => Proc.new { 5.seconds.from_now }
  
end
