class AlterPostTypeFbPosts < ActiveRecord::Migration
  def change
    change_column(:fb_posts, :post_type, :string, limit: 20, default: 'original')
  end
end
