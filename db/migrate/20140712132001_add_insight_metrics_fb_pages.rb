class AddInsightMetricsFbPages < ActiveRecord::Migration
  def change
    add_column :fb_pages, :stories_by_story_type_week, :string, :after=> :posts
    add_column :fb_pages, :stories_day_28, :integer, :after=> :posts
    add_column :fb_pages, :stories_week, :integer, :after=> :posts
    add_column :fb_pages, :consumptions_by_consumption_type_day, :string, :after=> :posts
    add_column :fb_pages, :consumptions_day, :integer, :after=> :posts
    add_column :fb_pages, :story_adds_by_story_type_day, :string, :after=> :posts
    add_column :fb_pages, :story_adds_day, :integer, :after=> :posts
    add_column :fb_pages, :fan_adds_day, :integer, :after=> :posts
  end
end
