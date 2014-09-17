#!/usr/bin/env ruby
# encoding: utf-8

require 'thread'
require "bunny"


class RateLimiter
  GLOBAL_LOCK = Mutex.new
  TICKS_PER_SECOND = 1000000000.to_f

  attr_reader :ticks_per_call, :max_per_second, :last_call_time  
  
  def initialize(max_per_second)
    @max_per_second = max_per_second
    @ticks_per_call = 1 / max_per_second.to_f
    @last_call_time = 0.0
    puts "TICKS PER CALL: #{ticks_per_call}"
  end

  def perform
    GLOBAL_LOCK.synchronize {
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - @last_call_time
      puts "ELAPSED: #{elapsed}"
      left_to_wait = ticks_per_call - elapsed
      puts "LEFT TO WAIT: #{left_to_wait}"
      if left_to_wait > 0
        sleep(left_to_wait)
      end
    }
    return yield
  ensure
    GLOBAL_LOCK.synchronize {
      @last_call_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    }
  end
end


conn = Bunny.new(:automatically_recover => false, :user => "admin", :password => "Rabbit123")
conn.start

begin
  ch   = conn.create_channel
  q    = ch.queue("hello")
  rate_limiter = RateLimiter.new(2)
  puts "Sending Messages..."
  counter = 0
  loop do
    rate_limiter.perform do
      ch.default_exchange.publish(counter.to_s, :routing_key => q.name)
      # puts " [x] Sent 'Hello World!'"
    end  
    counter += 1
  end
ensure
  conn.close
end