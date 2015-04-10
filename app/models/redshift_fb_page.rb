class RedshiftFbPage < Redshift
  self.table_name = "fb_pages"
  
class << self 
  def column_array
    ['total_likes' ,'total_comments' ,'total_shares' ,'total_talking_about',
          'likes' ,'comments','shares','posts' ,'replies_to_comment' ,'fan_adds_day',
          'story_adds_day','story_adds_by_story_type_day' ,'consumptions_day',
          'consumptions_by_consumption_type_day' ,'stories_week' ,
          'stories_day_28' ,'stories_by_story_type_week' ]
  end
end

end
=begin
def copy_from_fb_pages
    account_ids.each do | old_acc_id |
      RedshiftFbPage.where(account_id: old_acc_id ).all.each do | fp_old |
      begin
        d=fp_old.post_created_time
        fp_new = FbPage.where(account_id: new_acc_id).
             where(post_created_time: (d.beginning_of_day..d.end_of_day)).
             to_a.first
        if !fp_new
          fp_new = FbPage.create(account_id: new_acc.id,
                   object_name: new_acc.object_name,
                   post_created_time: d.middle_of_day)
        end
        column_array.each do |col|
          if fp_new.send(col).to_i < fp_old.send(col).to_i
            val = fp_old.send(col)
            fp_new.send("#{col}=", val)
          end
          fp_new.save
        end
      rescue exception=>ex
          logger.error "  RedshiftFbPage.copy_from_fb_pages #{ex.message}"
      end
    end
  end
=end
