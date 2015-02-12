class CreateFbPosts < ActiveRecord::Migration
  def up
    create_table :fb_posts do |t|
      t.integer :account_id
      t.string :post_id, :limit=>40
      t.integer :likes
      t.integer :comments
      t.integer :shares
      t.datetime :post_created_time
      t.timestamps
    end
    add_index :fb_posts, :account_id
    add_index :fb_posts, :post_created_time
    add_index :fb_posts, :post_id,:unique=>true
  end
  
  def down
    remove_index :fb_posts, :account_id
    remove_index :fb_posts, :post_created_time
    remove_index :fb_posts, :post_id
    drop_table :fb_posts
  end
  
end
