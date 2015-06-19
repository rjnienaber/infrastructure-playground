require "thread"
require "march_hare"
require 'pry'
java_import java.util.concurrent.ArrayBlockingQueue
java_import java.util.concurrent.TimeUnit

require 'logger'
LOGGER = Logger.new(STDOUT)
CONN = MarchHare.connect(:automatically_recover => false, :user => "admin", :password => "Rabbit123")
at_exit do
  CONN.close
end

require 'sinatra'

class ExecuteCommand
  attr_reader :queue, :connection, :channel, :server_queue

  def initialize(connection, server_queue)
    @connection = connection    
    @server_queue = server_queue
    @queue = ArrayBlockingQueue.new(1)
  end

  def call(value)
    channel = connection.create_channel
    reply_queue = channel.queue("", :exclusive => true)

    that = self
    reply_queue.subscribe(:auto_delete => true, :exclusive => true) do |payload|
      that.queue.put(payload)
    end

    exchange = channel.default_exchange
    exchange.publish(value.to_s, :routing_key => server_queue, :reply_to => reply_queue.name)
    
    result = queue.poll(5, TimeUnit::SECONDS) || 'Timed out'
    result + "\n"
  ensure
    reply_queue.delete if reply_queue
    channel.close    
  end
end

get '/execute_trade' do
  client = ExecuteCommand.new(CONN, 'rpc.execute_trade')
  client.call((params[:sleep] || 5).to_s)
end

get '/hello' do
  'Hello, world!'
end