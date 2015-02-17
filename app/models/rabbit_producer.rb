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
    #  `bundle exec clockworkd -c #{Rails.root}/app/models/clock.rb start --log`
    end  
  end
  
end

=begin

ruby -rubygems app/models/rabbit_producer.rb

  def self.amqp
    t = Thread.new { EventMachine.run }
    sleep(0.5)
    options = {:host => conf[:host], :username => conf[:username], :password =>conf[:password]}
    connection = AMQP.connect(options)
    channel    = AMQP::Channel.new(connection)
 
    # publish new commands every 3600 seconds
    EventMachine.add_periodic_timer(3600.0) do
      #FacebookAccount.where("page_access_token is not null").all.each do |account|
      #  account.retrieve channel
      #end
      TwitterAccount.where("is_active is not null").all.each do |account|
        account.retrieve channel
      end
    end
    puts "[boot] Ready"
    File.open("tmp/producer.id","w") {|file| file.write(Process.pid)}
    Signal.trap("INT") { connection.close { EventMachine.stop } }
    t.join
  end

  def self.amqp_send message="Voice of America"
    t = Thread.new { EventMachine.run }
    sleep(0.5)
    options = {:host => "127.0.0.1", :username => "oddidev", :password =>'oddi3600BBG'}
    connection = AMQP.connect(options)
    channel    = AMQP::Channel.new(connection)
 
    # publish new commands every 3 seconds
    EventMachine.add_periodic_timer(3600.0) do
      puts "Publishing a command (gems.install)"
      payload = { :gem => "rack", :version => "~> 1.3.0" }.to_yaml
      channel.default_exchange.publish(payload,
            :type        => "gems.install",
            :routing_key => "amqpgem.examples.patterns.command")
    end
    puts "[boot] Ready"
    Signal.trap("INT") { connection.close { EventMachine.stop } }
    t.join
  end


  def self.send
    # conn = Bunny.new
    conn = Bunny.new(:host => "127.0.0.1", :username => "oddidev", :password =>'oddi3600BBG')
    conn.start
    ch = conn.create_channel
    # q = ch.queue("amqpgem.examples.patterns.command")
    payload = { :gem => "rack", :version => "~> 1.3.0" }.to_yaml
    ch.default_exchange.publish(payload, 
       :type        => "gems.install",
       :routing_key => "amqpgem.examples.patterns.command")
    puts " [x] Sent 'Hello World!'"
    conn.close
  end
end


https://github.com/markiz/rubyonrails23_passenger_amqp_gem_example
https://github.com/ruby-amqp/amqp

https://gemnasium.com/npms/amqp-schedule

https://github.com/lazureykis/rabbit_jobs
https://github.com/danielrhodes/sidekiq-rabbitmq/blob/master/examples/clockwork.rb

require "rubygems"
require "amqp"

EventMachine.run do
  connection = AMQP.connect(:host => '127.0.0.1')
  puts "Connected to AMQP broker. Running #{AMQP::VERSION} version of the gem..."

  channel  = AMQP::Channel.new(connection)
  queue    = channel.queue("amqpgem.examples.helloworld", :auto_delete => true)
  exchange = channel.direct("")

  queue.subscribe do |payload|
    puts "Received a message: #{payload}. Disconnecting..."
    connection.close { EventMachine.stop }
  end

  exchange.publish "Hello, world!", :routing_key => queue.name
end
=end

=begin
class Consumer
  def handle_message(metadata, payload)
    puts "Received a message: #{payload}, content_type = #{metadata.content_type}"
  end # handle_message(metadata, payload)
end

class Worker
  
  def initialize(channel, queue_name = AMQ::Protocol::EMPTY_STRING, consumer = Consumer.new)
    @queue_name = queue_name
    @channel    = channel
    @channel.on_error(&method(:handle_channel_exception))
    @consumer   = consumer
  end # initialize

  def start
    @queue = @channel.queue(@queue_name, :exclusive => true)
    @queue.subscribe(&@consumer.method(:handle_message))
  end # start

  def handle_channel_exception(channel, channel_close)
    puts "Oops... a channel-level exception: code = #{channel_close.reply_code}, message = #{channel_close.reply_text}"
  end # handle_channel_exception(channel, channel_close)
  
end

class Producer
  def initialize(channel, exchange)
    @channel  = channel
    @exchange = exchange
  end # initialize(channel, exchange)

  def publish(message, options = {})
    @exchange.publish(message, options)
  end # publish(message, options = {})
  def handle_channel_exception(channel, channel_close)
    puts "Oops... a channel-level exception: code = #{channel_close.reply_code}, message = #{channel_close.reply_text}"
  end # handle_channel_exception(channel, channel_close)
end

AMQP.start("amqp://guest:guest@127.0.0.1") do |connection, open_ok|
  channel  = AMQP::Channel.new(connection)
  worker   = Worker.new(channel, "amqpgem.objects.integration")
  worker.start

  producer = Producer.new(channel, channel.default_exchange)
  puts "Publishing..."
  producer.publish("Hello, world", :routing_key => "amqpgem.objects.integration")

  # stop in 2 seconds
  EventMachine.add_timer(2.0) { connection.close { EventMachine.stop } }
end

=end
