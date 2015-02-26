#
# this class is to get data from a facebook page
# first get top level likes, all posts
class FbPost < ActiveRecord::Base
   
  after_save :sync_redshift
  
  def sync_redshift
    attr = self.attributes
    RedshiftFbPost.create_or_update(attr)
  end
  # bin/delayed_job restart 
  # to clear cache of method create_or_update
  handle_asynchronously :sync_redshift, :run_at => Proc.new { 5.seconds.from_now }
  
  
end
