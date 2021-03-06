require "clockwork"

require File.expand_path("../../../config/boot",        __FILE__)
require File.expand_path("../../../config/environment", __FILE__)

require "stalker"
#
TIME_GAP=1800 # seconds
def make_arr start_at
  gap = 8*3600 #=> 8 hours
  [to_time(start_at),to_time(start_at+gap),to_time(start_at+2*gap)]
end
  
def to_time(seconds)
  Time.at(seconds).utc.strftime("%H:%M")
end
# export RAILS_ENV=production; bundle exec clockworkd -c app/models/clock.rb start --log
# clockworkd.clock: pid file: /Users/lliu/development/hub/tmp/clockworkd.clock.pid
module Clockwork
  log_file_path = File.expand_path("../../../tmp/clockworkd.clock.output", __FILE__)
  puts log_file_path

  error_handler do |error|
    Airbrake.notify_or_ignore(error)
  end
  
  handler do |job, time|
    puts "Running #{job} , at #{time}"
    Stalker.enqueue(job,{},{:ttr=>3600})
  end
  configure do |config|
    config[:sleep_timeout] = 5
    config[:logger] = Logger.new(log_file_path)
    config[:tz] = "UTC"
    config[:max_threads] = 500
    config[:thread] = true
  end
  #  
  # start clockwork 2 minutes from now
  start_at = Time.zone.now+2.minutes
  arr = make_arr start_at
  puts "AAA #{arr}"
  every(1.hours, "Account .check_status") {Account.check_status}
  every(4.hours, "FacebookAccount .aggregate_data_daily(2.days.ago)"){FacebookAccount.aggregate_data_daily(2.days.ago)}
  every(1.day, "TwitterAccount .retrieve(30.days.ago)", :at => arr){TwitterAccount.retrieve(30.days.ago)}
  every(1.day, "YoutubeAccount .retrieve", {:at => arr}){YoutubeAccount.retrieve}
  
  start_at = start_at + TIME_GAP
  arr = make_arr start_at
  Rails.logger.debug arr
  puts arr
  every(1.day, "ScReferralTraffic .get_daily_report", {:at => arr}){ScReferralTraffic.get_daily_report}
  start_at = start_at + TIME_GAP
  arr = make_arr start_at
  puts arr
  every(1.day, "FacebookAccount .retrieve_extended(2.months.ago)", {:at => arr}){FacebookAccount.retrieve_extended(2.months.ago)}
  start_at = start_at + TIME_GAP
  arr = make_arr start_at
  puts arr
  every(1.day, "FacebookAccount .retrieve(28.days.ago,0,'0..15')", {:at => arr}){FacebookAccount.retrieve(28.days.ago,0,"0..15")}
  every(1.day, "FacebookAccount .retrieve(28.days.ago,0,'106..400')", {:at => arr}){FacebookAccount.retrieve(28.days.ago,0,"106..400")} 
  
  start_at = start_at + TIME_GAP
  arr = make_arr start_at
  puts arr
  every(1.day, "FacebookAccount .retrieve(28.days.ago,0,'16..30')", {:at => arr}){FacebookAccount.retrieve(28.days.ago,0,"16..30")} 
  every(1.day, "FacebookAccount .retrieve(28.days.ago,0,'91..105')", {:at => arr}){FacebookAccount.retrieve(28.days.ago,0,"91..105")}
  
  start_at = start_at + TIME_GAP
  arr = make_arr start_at
  puts arr
  every(1.day, "FacebookAccount .retrieve(28.days.ago,0,'31..45')", {:at => arr}){FacebookAccount.retrieve(28.days.ago,0,"31..45")}
  every(1.day, "FacebookAccount .retrieve(28.days.ago,0,'76..90')", {:at => arr}){FacebookAccount.retrieve(28.days.ago,0,"76..90")}
  
  start_at = start_at + TIME_GAP
  arr = make_arr start_at
  puts arr
  every(1.day, "FacebookAccount .retrieve(28.days.ago,0,'46..60')", {:at => arr}){FacebookAccount.retrieve(28.days.ago,0,"46..60")}
  every(1.day, "FacebookAccount .retrieve(28.days.ago,0,'61..75')", {:at => arr}){FacebookAccount.retrieve_extended(2.months.ago)}

end
=begin
  start_at = 21600 #>  06:00
  every(1.hours, "Account.check_status") {Account.check_status}
  every(4.hours, "FacebookAccount.aggregate_data_daily(2.days.ago)"){FacebookAccount.aggregate_data_daily(2.days.ago)}
  
  every(1.day, "TwitterAccount.retrieve(30.days.ago)", :at => ["6:00", "14:00","22:00"]){TwitterAccount.retrieve(30.days.ago)}
  every(1.day, "YoutubeAccount.retrieve", :at => ["6:30", "14:30","22:30"]){YoutubeAccount.retrieve}
  every(1.day, "ScReferralTraffic.get_daily_report", :at => ["7:00", "15:00","23:00"]){ScReferralTraffic.get_daily_report}
  
  every(1.day, "FacebookAccount.retrieve_extended(2.months.ago)", :at => ["7:30", "15:30","22:30"]){FacebookAccount.retrieve_extended(2.months.ago)}
  every(1.day, "FacebookAccount.retrieve(28.days.ago,0,"61..75")", :at => ["9:30", "17:30", "1:30"]){FacebookAccount.retrieve_extended(2.months.ago)}
  every(1.day, "FacebookAccount.retrieve(28.days.ago,0,"76..90")", :at => ["10:00", "18:00","2:00"]){FacebookAccount.retrieve(28.days.ago,0,"76..90")}
  every(1.day, "FacebookAccount.retrieve(28.days.ago,0,"91..105")", :at => ["10:20", "18:20","2:20"]){FacebookAccount.retrieve(28.days.ago,0,"91..105")}
  every(1.day, "FacebookAccount.retrieve(28.days.ago,0,"106..400")", :at => ["10:40", "18:40",":40"]){FacebookAccount.retrieve(28.days.ago,0,"106..400")}
  every(1.day, "FacebookAccount.retrieve(28.days.ago,0,"0..15")", :at => ["11:00", "19:30","3:00"]){FacebookAccount.retrieve(28.days.ago,0,"0..15")}
  every(1.day, "FacebookAccount.retrieve(28.days.ago,0,"16..30")", :at => ["11:30", "19:30","3:30"]){FacebookAccount.retrieve(28.days.ago,0,"16..30")}
  every(1.day, "FacebookAccount.retrieve(28.days.ago,0,"31..45")", :at => ["12:00", "20:00","4:00"]){FacebookAccount.retrieve(28.days.ago,0,"31..45")}
  every(1.day, "FacebookAccount.retrieve(28.days.ago,0,"46..60")", :at => ["12:30", "20:30","4:30"]){FacebookAccount.retrieve(28.days.ago,0,"46..60")}
=end

