class StoryTypeDay < TableLess
 
  attr_accessor :name,:date, :other,:fan,:page_post,:user_post,:checkin,:mention,:question
  
  def self.sum story_type_str, start_date, end_date
    rec  = OpenStruct.new
    records = []
    json_array = story_type_str.split('|')
    json_array.each do |json_str|
      records << JSON.parse(json_str)
    end
    rec.name = "page_story_adds_by_story_type_day"
        
    rec.other = records.map { |h| h['other'].to_i }.sum
    rec.fan = records.map { |h| h['fan'].to_i}.sum
    rec.page_post = records.map { |h| h['page post'].to_i }.sum
    rec.user_post = records.map { |h| h['user post'].to_i }.sum
    rec.checkin = records.map { |h| h['checkin'].to_i }.sum
    rec.mention = records.map { |h| h['mention'].to_i }.sum
    rec.question = records.map { |h| h['question'].to_i }.sum
    rec.to_h
  end
  
  # input array of ActiveRecord
  def self.sum_period records, start_date, end_date
    rec  = OpenStruct.new
    rec.name = "page_story_adds_by_story_type_day"
    rec.period  = "#{start_date.strftime('%Y-%m-%d')} - #{end_date.strftime('%Y-%m-%d')}"

    rec.other = records.map { |h| h[:other].to_i }.sum
    rec.fan = records.map { |h| h[:fan].to_i}.sum
    rec.page_post = records.map { |h| h[:page_post].to_i }.sum
    rec.user_post = records.map { |h| h[:user_post].to_i }.sum
    rec.checkin = records.map { |h| h[:checkin].to_i }.sum
    rec.mention = records.map { |h| h[:mention].to_i }.sum
    rec.question = records.map { |h| h[:question].to_i }.sum
    rec.to_h
  end
  
end

