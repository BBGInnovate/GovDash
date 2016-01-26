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
  
  since_date = 5.months.ago
  ids = FacebookAccount.more_history_data_ids
  at_minute = {}
  
  configure do |config|
    config[:sleep_timeout] = 5
    config[:logger] = Logger.new(log_file_path)
    config[:tz] = 'EST'
    config[:max_threads] = 500
    config[:thread] = true
  end
  
  FacebookAccount.where(["id in (?)",ids]).to_a.each_ do | acc |
    acc.since_date = since_date
    every(6.hours, "Retrieve FB Account #{acc.id}", at_minute) {    
      ActiveRecord::Base.connection_pool.with_connection do |conn|
        begin
          acc.retrieve
        rescue Exception=>ex
          res = "Retrieve FB Account #{acc.id} #{ex.message}"
          res = " #{res} #{ex.backtrace[0]}"
          puts res
        end
      }
    end
  end
end

