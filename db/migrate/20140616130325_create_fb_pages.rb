class CreateFbPages < ActiveRecord::Migration
  def up
    create_table :fb_pages do |t|
      t.integer :account_id
      t.string :object_name, :limit=>40
      t.integer :total_likes
      t.integer :total_comments
      t.integer :total_shares
      t.integer :total_talking_about
      
      t.integer :likes
      t.integer :comments
      t.integer :shares
      t.integer :posts
      t.datetime :post_created_time # store the earliest retrieved post created_time
      t.timestamps
    end
    add_index :fb_pages, :post_created_time
    add_index :fb_pages, :account_id
  end
  
  def down
    remove_index :fb_pages, :account_id
    remove_index :fb_pages, :post_created_time
    drop_table :fb_pages
  end
  
end
=begin
@id = object_name
@feeds = @api.get_connections(@id, "posts", :fields=>"id,created_time",:limit=>1000, :since=>1.day.ago, :until=>Time.now)
@feeds = @feeds.next_page => get total count of posts
store each post_id in fb_posts table

for each post_id in fb_posts
  fql = "SELECT like_info.like_count, comment_info.comment_count, share_count FROM stream  WHERE post_id = '#{post_id}'"
  @comments = @api.fql_query(fql)
[{"like_info"=>{"like_count"=>3487}, "comment_info"=>{"comment_count"=>262}, "share_count"=>276}] 
  store comment_count, share_count in fb_posts for the post_id
  sum(comment_count) in fb_posts and store fb_page_results for the fb_page_id , eg. voiceofamerica
=end