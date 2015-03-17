#!/usr/bin/env ruby
# encoding: utf-8

require "bunny"
require 'amqp'
require "yaml"
require Rails.root.to_s + '/lib/rabbit'

class RabbitReceiver
  include Process
  include Rabbit
  
  def self.consumers
    amqp_consumer ['upload','retrieve','initial_load']
  end

  def self.amqp_consumer(queue_names)
    queues = []
    t = Thread.new { EventMachine.run }
    EventMachine.next_tick do
      puts "Connected to AMQP broker. Running #{AMQP::VERSION} version of the gem..."
      queue_names.each_with_index do | queue_name, i |      
        queues[i] = amqp_channel.queue("amqpgem.#{queue_name}",:durable => true, :auto_delete => false)
        Rails.logger.info "[boot] AMQP Queue amqpgem.#{queue_name} Ready. "        
        queues[i].subscribe do |metadata, payload|
          puts "Received a message: #{payload}"
          data = YAML.load(payload) 
          do_action data, metadata
        end
      end
    end
    t.join
    Signal.trap("INT") { @amqp_connection.close { EventMachine.stop } }
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
    begin
      id = data[:id]
      klass = data[:klass].constantize
      obj = klass.find_by id: id
      Rails.logger.info "RabbitReceiver : Received a #{metadata.type} request with #{data.inspect}"   
      if obj 
        if obj.respond_to? metadata.type
          obj.send metadata.type
        else
          Rails.logger.info "  #{obj.class.name} - Unknown method: #{metadata.type}"
        end
      else
        Rails.logger.info "  #{klass.name} - not found by id: #{id}"
      end
    rescue Exception=>e
      Rails.logger.error "  #{Time.now.to_s(:db)} #{metadata.type} do_action. Error : #{e.message}"
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
    @amqp_channel.auto_recovery = true
    if @amqp_channel.auto_recovering?
      Rails.logger.info "  Channel #{@amqp_channel.id} IS auto-recovering"
    end
    @amqp_connection.on_tcp_connection_loss do |conn, settings|
      Rails.logger.info "   [network failure] Trying to reconnect..."
      conn.reconnect(false, 2)
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

