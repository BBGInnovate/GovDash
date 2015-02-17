#!/usr/bin/env ruby
# encoding: utf-8

require "bunny"
# require 'amqp'
require "yaml"
require Rails.root.to_s + '/lib/rabbit'

class RabbitProducer
  include Rabbit

  def connection
    conf = self.class.conf
    @connection ||= Bunny.new(:host => conf[:host], :username => conf[:username], :password =>conf[:password])
  end
  
  def channel
    unless @channel
      connection.start
      @channel = connection.create_channel
    end
    @channel
  end

  def self.restart_jobs
    pid = `pidof clockworkd.clock`.to_i
    `#{Rails.root}/gracefully-kill #{pid}`  if pid > 0
    pid = clockworkd_pid
    if pid == 0
      `bundle exec clockworkd -c #{Rails.root}/app/models/clock.rb start --log`
    end  
  end
  
end

