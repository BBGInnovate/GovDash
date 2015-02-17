class StoryTypeWeek < TableLess
 
  attr_accessor :name,:date, :other,:fan,:page_post,:user_post,:checkin,
                :coupon,:mention,:question
  
  def self.summarize arr_json_str, start_date, end_date
    rec  = OpenStruct.new
    # start_date = records.first.date
    # end_date = records.last.date
    arr_hsh = []
    arr_json_str.each do |json_str|
      arr_hsh << JSON.parse(json_str).to_h.with_indifferent_access
    end
    rec.name = "page_stories_by_story_type_week"
    rec.date  = start_date.strftime('%Y-%m-%d')
    rec.other = arr_hsh.map { |h| h[:other].to_i }.sum
    rec.fan = arr_hsh.map { |h| h[:fan].to_i}.sum
    rec.page_post = arr_hsh.map { |h| h[:page_post].to_i }.sum
    rec.user_post = arr_hsh.map { |h| h[:user_post].to_i }.sum
    rec.checkin = arr_hsh.map { |h| h[:checkin].to_i }.sum
    rec.coupon = arr_hsh.map { |h| h[:coupon].to_i }.sum
    rec.mention = arr_hsh.map { |h| h[:mention].to_i }.sum
    rec.question = arr_hsh.map { |h| h[:question].to_i }.sum
    rec.to_h
  end
  
  # input array of ActiveRecord
  def self.sum records, start_date, end_date
    rec  = OpenStruct.new
    # start_date = records.first.date
    # end_date = records.last.date
    rec.name = "page_stories_by_story_type_week"
    rec.period  = "#{start_date.strftime('%Y-%m-%d')} - #{end_date.strftime('%Y-%m-%d')}"
    rec.other = records.map { |h| h.other.to_i }.sum
    rec.fan = records.map { |h| h.fan.to_i}.sum
    rec.page_post = records.map { |h| h.page_post.to_i }.sum
    rec.user_post = records.map { |h| h.user_post.to_i }.sum
    rec.checkin = records.map { |h| h.checkin.to_i }.sum
    rec.coupon = records.map { |h| h.coupon.to_i }.sum
    rec.mention = records.map { |h| h.mention.to_i }.sum
    rec.question = records.map { |h| h.question.to_i }.sum
    rec.to_h
  end
  
end

=begin
class StoryTypeWeek < ActiveRecord::Base
  has_no_table
  column :end_time, :datetime
  column :other, :integer
  column :fan, :integer
  column :page_post, :integer
  column :user_post, :integer
  column :checkein, :integer
  column :coupon, :integer
  column :mention, :integer
  column :question, :integer
  
  # validates_presence_of :name, :email
  
end

=end

