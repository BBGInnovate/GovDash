require 'clockwork'

require File.expand_path('../../../config/boot',        __FILE__)
require File.expand_path('../../../config/environment', __FILE__)

require 'stalker'
#
# bundle exec clockwork app/models/clock.rb
# RAILS_ENV=development bundle exec clockworkd -c app/models/clock.rb start --log
# clockworkd.clock: pid file: /Users/lliu/development/hub/tmp/clockworkd.clock.pid
module Clockwork
  log_file_path = File.expand_path('../../../tmp/clockworkd.clock.output', __FILE__)
  puts log_file_path

  handler { |job| Stalker.enqueue(job) }
  configure do |config|
    config[:sleep_timeout] = 5
    config[:logger] = Logger.new(log_file_path)
    config[:tz] = 'EST'
    config[:max_threads] = 500
    config[:thread] = true
  end
  
  every(1.minute, 'FacebookAccount.retrieve(28.days.ago,0,"76..90")'){ puts "AAA #{Time.now}"}
  
=begin
  every(1.hours, 'Account.check_status') {Account.check_status}
  every(4.hours, 'FacebookAccount.aggregate_data_daily(2.days.ago)'){FacebookAccount.aggregate_data_daily(2.days.ago)}
  every(1.day, 'TwitterAccount.retrieve(30.days.ago)', :at => ['6:00', '14:00','22:00']){TwitterAccount.retrieve(30.days.ago)}
  every(1.day, 'ScReferralTraffic.get_daily_report', :at => ['7:00', '15:00','23:00']){ScReferralTraffic.get_daily_report}
  every(1.day, 'YoutubeAccount.retrieve', :at => ['7:30', '15:30','23:30']){YoutubeAccount.retrieve}
  every(1.day, 'FacebookAccount.retrieve_extended(2.months.ago)', :at => ['8:00', '16:00','23:59']){FacebookAccount.retrieve_extended(2.months.ago)}
  every(1.day, 'FacebookAccount.retrieve(28.days.ago,0,"61..75")', :at => ['9:30', '17:30', '1:30']){FacebookAccount.retrieve_extended(2.months.ago)}
  every(1.day, 'FacebookAccount.retrieve(28.days.ago,0,"76..90")', :at => ['10:00', '18:00','2:00']){FacebookAccount.retrieve(28.days.ago,0,"76..90")}
  every(1.day, 'FacebookAccount.retrieve(28.days.ago,0,"91..105")', :at => ['10:20', '18:20','2:20']){FacebookAccount.retrieve(28.days.ago,0,"91..105")}
  every(1.day, 'FacebookAccount.retrieve(28.days.ago,0,"106..400")', :at => ['10:40', '18:40',':40']){FacebookAccount.retrieve(28.days.ago,0,"106..400")}
  every(1.day, 'FacebookAccount.retrieve(28.days.ago,0,"0..15")', :at => ['11:00', '19:30','3:00']){FacebookAccount.retrieve(28.days.ago,0,"0..15")}
  every(1.day, 'FacebookAccount.retrieve(28.days.ago,0,"16..30")', :at => ['11:30', '19:30','3:30']){FacebookAccount.retrieve(28.days.ago,0,"16..30")}
  every(1.day, 'FacebookAccount.retrieve(28.days.ago,0,"31..45")', :at => ['12:00', '20:00','4:00']){FacebookAccount.retrieve(28.days.ago,0,"31..45")}
  every(1.day, 'FacebookAccount.retrieve(28.days.ago,0,"46..60")', :at => ['12:30', '20:30','4:30']){FacebookAccount.retrieve(28.days.ago,0,"46..60")}
=end
end

