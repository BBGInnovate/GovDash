class CreateTwTweets < ActiveRecord::Migration
  def up
    if TwTweet.table_exists?
       drop_table :tw_tweets
    end
    
    create_table :tw_tweets do |t|
      t.integer :account_id
      t.integer :tweet_id, :limit => 8
      t.integer :retweets
      t.integer :favorites
      t.integer :mentions
      t.datetime :tweet_created_at
      t.timestamps
    end
    add_index :tw_tweets, :account_id
    add_index :tw_tweets, :tweet_id
    add_index :tw_tweets, :tweet_created_at
  end
  
  def down
    remove_index :tw_tweets, :account_id
    remove_index :tw_tweets, :tweet_id
    remove_index :tw_tweets, :tweet_created_at
    drop_table :tw_tweets
  end
end
