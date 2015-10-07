class ReplicaFbPost < Replica
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


