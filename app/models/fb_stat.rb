#
# this class is to get data from a facebook page
# first get top level likes, all posts
# require Rails.root.to_s + '/lib/read_stat_detail'
class FbStat < StatDetail 
  # include ReadStatDetail
  def self.table_class
    REPLICA ? ReplicaFbPage : FbPage
  end
  def self.created_at
    "post_created_time"
  end
  def self.data_columns
    # in database select query:
    # select fan_adds_day AS page_likes
    {'fan_adds_day' => 'page_likes',
     'likes' => 'story_likes',
     'replies_to_comment+comments'=>'comments',
     'shares'=>'shares'}
  end
end
