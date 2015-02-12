class CreateTwTimelines < ActiveRecord::Migration
  def up
    if TwTimeline.table_exists?
       drop_table :tw_timelines
    end
    
    create_table :tw_timelines do |t|
      t.integer :account_id
      t.string :object_name, :limit=>40
      t.integer :total_tweets
      t.integer :total_favorites
      t.integer :total_followers
      
      t.integer :tweets
      t.integer :favorites
      t.integer :followers
      t.integer :retweets
      t.integer :mentions
      t.datetime :tweet_created_at
      t.timestamps
    end
    add_index :tw_timelines, :account_id
    add_index :tw_timelines, :tweet_created_at
  end
  
  def down
    remove_index :tw_timelines, :account_id
    remove_index :tw_timelines, :tweet_created_at
    drop_table :tw_timelines
  end
  
end
