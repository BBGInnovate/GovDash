require 'delayed/worker'
Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.sleep_delay = 10
Delayed::Worker.max_attempts = 1
Delayed::Worker.max_run_time = 2.hour
Delayed::Worker.read_ahead = 10
Delayed::Worker.delay_jobs = true#!Rails.env.test?
Delayed::Worker.logger = Rails.logger


module Delayed
  class Worker
    def say_with_flushing(text, level = Logger::INFO)
      if logger
        say_without_flushing(text, level)
        logger.flush
      end
    end
    alias_method_chain :say, :flushing
  end
end