require 'sinatra'
require "thread"
require "march_hare"
require 'pry'
java_import java.util.concurrent.ArrayBlockingQueue
java_import java.util.concurrent.TimeUnit

require 'logger'
LOGGER = Logger.new(STDOUT)

class ExecuteCommand
  attr_reader :queue, :conn, :channel

  def initialize(server_queue)
    @conn = MarchHare.connect(:automatically_recover => false, :user => "admin", :password => "Rabbit123")
    @channel = conn.create_channel
    @default_exchange = @channel.default_exchange
    @server_queue = server_queue
    @reply_queue = @channel.queue("", :exclusive => true)

    @queue = ArrayBlockingQueue.new(1)
    that = self

    @reply_queue.subscribe do |payload|
      that.queue.put(payload)
    end
  end

  def call(value)
    @default_exchange.publish(value.to_s, :routing_key => @server_queue, :reply_to => @reply_queue.name)
    
    result = queue.poll(5, TimeUnit::SECONDS) || 'Timed out'
    result + "\n"
  ensure
    channel.close
    conn.close
  end
end

get '/execute_trade' do
  client = ExecuteCommand.new('rpc.execute_trade')
  client.call((params[:sleep] || 5).to_s)
end

get '/hello' do
  'Hello, world!'
end