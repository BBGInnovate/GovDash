#!/usr/bin/env ruby
# encoding: utf-8

require "bunny"
require 'amqp'
require "yaml"
require Rails.root.to_s + '/lib/rabbit'

=begin
Install RabbitMQ
echo "deb http://www.rabbitmq.com/debian/ testing main" > /etc/apt/sources.list.d/rabbitmq.list
wget http://www.rabbitmq.com/rabbitmq-signing-key-public.asc
sudo apt-key add rabbitmq-signing-key-public.asc
apt-get update
apt-get install rabbitmq-server -y

service rabbitmq-server start
sbin/rabbitmq-plugins enable rabbitmq_management
sbin/rabbitmqctl add_user oddidev ab530a13e45914982b
sbin/rabbitmqctl set_user_tags oddidev administrator
sbin/rabbitmqctl set_permissions -p / oddidev ".*" ".*" ".*"
# rabbitmqctl delete_user guest
sbin/rabbitmq-server restart
sbin/rabbitmqctl status
# Make sure to open the correct firewall ports (15672, 5672)
http://localhost:15672/
=end

=begin
18 4 * * * /bin/bash -l -c 'source /home/lliu/.rvm/scripts/rvm; \
   cd /home/lliu/socialdash/current && bundle exec rails runner -e production  "RabbitReceiver.consumers"'  > /tmp/mq-receiver.log 2>&1

=end

class RabbitReceiver
  include Process
  include Rabbit
  
  def self.consumers
    bunny_consumer
    amqp_consumer
  end

  def self.amqp_consumer(klass_name="TwitterAccount")
    t = Thread.new { EventMachine.run }
    sleep(0.5)
    amqp_channel.queue("amqpgem.#{klass_name}", :durable => true, :auto_delete => false).subscribe(:ack => true) do |metadata, payload|
      data = YAML.load(payload) 
      do_action data, metadata
      # message is processed, acknowledge it so that broker discards it
      metadata.ack
    end
    
    # File.open("tmp/receiver.id","w") {|file| file.write(Process.pid)}
    puts "[boot] AMQP Queue amqpgem.TwitterAccount Ready. "
    Signal.trap("INT") { @amqp_connection.close { EventMachine.stop } }
    t.join
    
  end
  
  def self.bunny_consumer(klass_name="FacebookAccount")
    bunny_channel.prefetch(1)
    hi_q = bunny_channel.queue("amqpgem.#{klass_name}", :durable => true, :auto_delete => false)
    hi_q.subscribe do |delivery_info,metadata, payload|
      data = YAML.load(payload)
      do_action data, metadata
    end
    puts "[boot] Bunny Queue amqpgem.#{klass_name} Ready. "
    Signal.trap("INT") { @bunny_connection.close { EventMachine.stop } }
  end
  
  protected
  
  def self.do_action data, metadata
    account_id = data[:account_id] 
    account = Account.find_by_id account_id
    puts "RabbitReceiver : Received a #{metadata.type} request with #{data.inspect}"  
    begin  
      case metadata.type
      when "retrieve"
         account.retrieve 
      else
         puts "[commands] Unknown command: #{metadata.type}"
      end
    rescue Exception=>e
      puts "Error : #{e.message}"
    end
  end
  
  def self.server_options
    @options ||= {:host => conf[:host], :username => conf[:username], :password =>conf[:password]}   
  end
  
  def self.amqp_channel
    if !@amqp_channel
      @amqp_connection = AMQP.connect(server_options)
      @amqp_channel = AMQP::Channel.new(@amqp_connection, :auto_recovery => true)
    end
    @amqp_channel
  end
  
  def self.bunny_channel
    if !@bunny_channel
      @bunny_connection = Bunny.new(server_options)
      @bunny_connection.start
      @bunny_channel = @bunny_connection.create_channel
    end
    @bunny_channel
  end
  
end
=begin
def self.receive
    t = Thread.new { EventMachine.run }
    sleep(0.5)
    options = {:host => conf[:host], :username => conf[:username], :password =>conf[:password]}
    connection = AMQP.connect(options)

    channel = AMQP::Channel.new(connection, :auto_recovery => true)
    channel.prefetch(1)
    channel.queue("amqpgem.FacebookAccount", :durable => true, :auto_delete => false).subscribe(:ack => true) do |metadata, payload|
      data = YAML.load(payload) 
      puts "RabbitReceiver : Received a #{metadata.type} request with #{data.inspect}"    
      case metadata.type
      when "retrieve"
         account_id = data[:account_id] 
         account = FacebookAccount.find_by_id account_id
         account.retrieve
      else
        puts "[commands] Unknown command: #{metadata.type}"
      end
      # message is processed, acknowledge it so that broker discards it
      metadata.ack
    end
    
    channel.queue("amqpgem.TwitterAccount", :durable => true, :auto_delete => false).subscribe(:ack => true) do |metadata, payload|
      data = YAML.load(payload) 
      msg = "RabbitReceiver : Received a #{metadata.type} request with #{data.inspect}"
      puts msg
      Account.logger.info msg
      case metadata.type
      when "retrieve"
         account_id = data[:account_id] 
         account = TwitterAccount.find_by_id account_id
         account.retrieve
      else
        msg = "[commands] Unknown command: #{metadata.type}"
        puts msg
        Account.logger.info msg
      end
      # message is processed, acknowledge it so that broker discards it
      metadata.ack
    end
    
    File.open("tmp/receiver.id","w") {|file| file.write(Process.pid)}
    puts "[boot] Ready. Will be publishing commands every 10 seconds."
    Signal.trap("INT") { File.delete("tmp/receiver.id") ; connection.close { EventMachine.stop } }
    t.join
    
  end
  # RabbitReceiver.receive
=end

