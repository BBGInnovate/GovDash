class Fbpage < ActiveRecord::Base
  belongs_to :account

  def Fbpage.column_array
    ['total_likes']
  end
  # after_save :sync_redshift
  def Fbpage.copy_from_fb_pages
    i = 0
    FacebookAccount.where("id>0").where("is_active=1").to_a.each do |acc|
      mypages = acc.fbpages
      acc.fb_pages.where("total_likes is not null").to_a.each do |fp_old|
        begin
          d=fp_old.post_created_time
          fp_new = mypages.where(post_created_time: (d.beginning_of_day..d.end_of_day)).
             to_a.first
          if !fp_new
            fp_new = acc.fbpages.create(:post_created_time=>d.middle_of_day)
          end
          changed = false
          column_array.each do |col|
            if fp_new.send(col).to_i < fp_old.send(col).to_i
               val = fp_old.send(col)
               fp_new.send("#{col}=", val)
               changed = true
            end
          end
          if changed
            # puts "   Updating #{fp_new.object_name} #{fp_new.id}"
            fp_new.save
          else
           # puts "   Nothing changed"
          end
        rescue Exception=>ex
          logger.error "  Fbpage.copy_from_fb_pages #{ex.message}"
        end
      end
      puts "  Finished account: #{acc.object_name} #{acc.id}"
      STDOUT.flush
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





