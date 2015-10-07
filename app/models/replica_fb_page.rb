class ReplicaFbPage < Replica
  self.table_name = "fb_pages"
  
class << self 
  def column_array
    ['total_likes' ,'total_comments' ,'total_shares' ,'total_talking_about',
          'likes' ,'comments','shares','posts' ,'replies_to_comment' ,'fan_adds_day',
          'story_adds_day','story_adds_by_story_type_day' ,'consumptions_day',
          'consumptions_by_consumption_type_day' ,'stories_week' ,
          'stories_day_28' ,'stories_by_story_type_week' ]
  end
  def date_array
    []
  end
  
end

end

