#
# this class is to get data from a facebook page
# first get top level likes, all posts
#
class FbPage < ActiveRecord::Base
  belongs_to :account

  # after_save :sync_redshift

  protected
  
  def sync_redshift
    attr = self.attributes
    RedshiftFbPage.create_or_update(attr)
  end
  # bin/delayed_job restart 
  # to clear cache of method create_or_update
  handle_asynchronously :sync_redshift, :run_at => Proc.new { 5.seconds.from_now }

end





