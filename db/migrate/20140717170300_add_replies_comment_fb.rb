class AddRepliesCommentFb < ActiveRecord::Migration
  def up

    if FbPage.connection.column_exists?('fb_pages','replies_to_comment')
      remove_column "fb_pages",:replies_to_comment
    end
    if FbPost.connection.column_exists?('fb_posts','replies_to_comment')
      remove_column "fb_posts",:replies_to_comment
    end

    unless FbPage.connection.column_exists?('fb_pages','replies_to_comment')
      add_column "fb_pages",:replies_to_comment, :integer,:after=> :posts
    end
    unless FbPost.connection.column_exists?('fb_posts','replies_to_comment')
      add_column "fb_posts",:replies_to_comment, :integer,:after=> :shares
    end
    unless FbPost.connection.column_exists?('fb_posts','post_type')
      add_column "fb_posts",:post_type, :string, :limit=>20,:after=> :shares
    end
  end
  
  def down
    if FbPage.connection.column_exists?('fb_pages','replies_to_comments')
      remove_column "fb_pages",:replies_to_comment
    end
    if FbPost.connection.column_exists?('fb_posts','replies_to_comments')
      remove_column "fb_posts",:replies_to_comment
      remove_column "fb_posts",:post_type
    end
  end
  
end
