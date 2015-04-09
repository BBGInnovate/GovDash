class Fbpage < ActiveRecord::Base
  belongs_to :account

  # after_save :sync_redshift
  def Fbpage.copy_from_fb_pages
    i = 0
    FacebookAccount.where("id>0").where("is_active=1").to_a.each do |acc|
      mypages = acc.fbpages
      acc.fb_pages.where("total_likes is not null").to_a.each do |fp_old|
        d=fp_old.post_created_time
        fp_new = mypages.where(post_created_time: (d.beginning_of_day..d.end_of_day)).
          to_a.first
        if !fp_new
          fp_new = acc.fbpages.create(:post_created_time=>d.middle_of_day)
        end
        
        if !fp_new.total_likes || (fp_new.total_likes < fp_old.total_likes)
          puts " #{fp_new.total_likes} = #{fp_old.total_likes}"
          fp_new.total_likes = fp_old.total_likes
          fp_new.save
          
        end
      end
    end
  end

  protected
  
  def sync_redshift
    attr = self.attributes
    RedshiftFbPage.create_or_update(attr)
  end
  # bin/delayed_job restart 
  # to clear cache of method create_or_update
  handle_asynchronously :sync_redshift, :run_at => Proc.new { 5.seconds.from_now }

end





