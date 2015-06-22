require 'sinatra'
require "thread"
require "march_hare"
require 'pry'
java_import java.util.concurrent.ArrayBlockingQueue
java_import java.util.concurrent.TimeUnit

require 'logger'
LOGGER = Logger.new(STDOUT)

class ExecuteCommand
  attr_reader :reply_queue, :queue, :correlation_id, :default_exchange
  attr_accessor :response

  def initialize(ch, server_queue)
    @default_exchange = ch.default_exchange
    @server_queue = server_queue
    @reply_queue = ch.queue("", :exclusive => true)

    @queue = ArrayBlockingQueue.new(1)
    @correlation_id = java.util.UUID.randomUUID().to_s
    that = self

    @reply_queue.subscribe do |payload|
      that.queue.put(payload)
    end
  end

  def call(value)
    @default_exchange.publish(value.to_s,
      :routing_key    => @server_queue,
      :correlation_id => correlation_id,
      :reply_to       => @reply_queue.name)
    
    result = queue.poll(5, TimeUnit::SECONDS) || 'Timed out'
    result + "\n"
  end
end

get '/execute_trade' do
  conn = MarchHare.connect(:automatically_recover => false, :user => "admin", :password => "Rabbit123")
  ch = conn.create_channel

  client = ExecuteCommand.new(ch, 'rpc.execute_trade')
  begin
    response = client.call((params[:sleep] || 5).to_s)
  ensure
    ch.close
    conn.close
  end
end

get '/hello' do
  'Hello, world!'
end