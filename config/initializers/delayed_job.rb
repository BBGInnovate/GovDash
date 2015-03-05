require 'delayed/worker'

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