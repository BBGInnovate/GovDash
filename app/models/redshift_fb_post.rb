class RedshiftFbPost < Redshift
  self.table_name = 'fb_posts'

class << self
  def column_array
    ['likes' ,'comments','shares']
  end
  def date_array
    ['post_created_time']
  end
end
end

=begin
  def RedshiftFbPost.copy_from_fb_posts
    old_acc_ids = RedshiftFbPage.select("distinct account_id").to_a
    old_acc_ids.each do | old_acc_id |
      obj_name = RedshiftFbPage.find_by(account_id: old_acc_id).object_name
      new_acc = FacebookAccount.find_by object_name: obj_name
      RedshiftFbPost.where(account_id: old_acc_id ).all.each do | fp_old |
      begin
        d=fp_old.post_created_time
        fp_new = FbPost.find_by(post_id: fp_old.post_id)
        if !fp_new
          fp_new = FbPost.create(account_id: new_acc.id,
                   post_id: fp_old.post_id
                   post_created_time: fp_old.post_created_time)
        end
        ['likes' ,'comments','shares'].each do |col|
          if fp_new.send(col).to_i < fp_old.send(col).to_i
            val = fp_old.send(col)
            fp_new.send("#{col}=", val)
          end
          fp_new.post_type = fp_old.post_type
          fp_new.save
        rescue exception=>ex
          logger.error "  RedshiftFbPage.copy_from_fb_pages #{ex.message}"
        end
      end
    end
  end
=end

