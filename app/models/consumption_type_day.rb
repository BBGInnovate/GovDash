class ConsumptionTypeDay < TableLess
  attr_accessor :name,:date, :other_clicks,:video_play, :link_clicks,:photo_view
 
  # input array of ActiveRecord
  def self.sum records,start_date, end_date
    rec  = OpenStruct.new
    rec.name = "page_consumptions_by_consumption_type_day"
    rec.period  = "#{start_date.strftime('%Y-%m-%d')} - #{end_date.strftime('%Y-%m-%d')}"
    rec.other_clicks = records.map { |h| h.other_clicks.to_i }.sum
    rec.video_play = records.map { |h| h.video_play.to_i }.sum
    rec.link_clicks = records.map { |h| h.link_clicks.to_i }.sum
    rec.photo_view = records.map { |h| h.photo_view.to_i }.sum
    rec.to_h
  end
  
end
