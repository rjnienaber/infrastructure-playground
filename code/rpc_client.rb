#!/usr/bin/env ruby
# encoding: utf-8

require "bunny"
require "thread"

conn = Bunny.new(:automatically_recover => false, :user => "admin", :password => "Rabbit123")
conn.start

ch   = conn.create_channel

class FibonacciClient
  attr_reader :reply_queue
  attr_accessor :response, :call_id
  attr_reader :lock, :condition

  def initialize(ch, server_queue)
    @ch             = ch
    @x              = ch.default_exchange

    @server_queue   = server_queue
    @reply_queue    = ch.queue("", :exclusive => true)


    @lock      = Mutex.new
    @condition = ConditionVariable.new
    that       = self

    @reply_queue.subscribe do |delivery_info, properties, payload|
      if properties[:correlation_id] == that.call_id
        that.response = payload.to_i
        that.lock.synchronize{that.condition.signal}
      end
    end
  end

  def call(n)
    self.call_id = self.generate_uuid

    @x.publish(n.to_s,
      :routing_key    => @server_queue,
      :correlation_id => call_id,
      :reply_to       => @reply_queue.name)
    
    lock.synchronize{condition.wait(lock)}
    response
  end

  protected

  def generate_uuid
    # very naive but good enough for code
    # examples
    "#{rand}#{rand}#{rand}"
  end
end


client   = FibonacciClient.new(ch, "rpc_queue")
size = ARGV[0].to_i
puts " [x] Requesting fib(#{size})"
response = client.call(size)
puts " [.] Got #{response}"

ch.close
conn.close
