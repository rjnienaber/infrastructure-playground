require 'sinatra'
require "thread"
require "march_hare"
require 'pry'
java_import java.util.concurrent.Executors
java_import java.util.concurrent.ArrayBlockingQueue
java_import java.util.concurrent.ConcurrentHashMap
java_import java.util.concurrent.TimeUnit
java_import java.util.UUID

require 'logger'
LOGGER = Logger.new(STDOUT)

RESPONSE_MAP = ConcurrentHashMap.new
EXECUTOR = Executors.new_fixed_thread_pool(16)

class ExecuteCommand
  attr_reader :reply_queue, :queue, :correlation_id, :exchange
  attr_accessor :response

  def initialize(ch, server_queue)
    @exchange = ch.default_exchange
    @server_queue = server_queue
    @reply_queue = ch.queue("rpc.execute_trade_response")

    @queue = ArrayBlockingQueue.new(1)
    @correlation_id = UUID.randomUUID().to_s
    # LOGGER.info "PUT: #{correlation_id}" 
    RESPONSE_MAP.put(correlation_id, queue)

    @reply_queue.subscribe(:ack => true) do |delivery_info, payload|
      EXECUTOR.submit do
        # LOGGER.info "REMOVE: #{delivery_info.properties.correlation_id}"
        RESPONSE_MAP.remove(delivery_info.properties.correlation_id).put(payload)
        ch.ack(delivery_info.delivery_tag)
      end
    end
  end

  def call(value)   
    # LOGGER.info "PUBLISH: #{correlation_id}" 
    @exchange.publish(value.to_s,
      :routing_key    => @server_queue,
      :correlation_id => correlation_id,
      :reply_to       => @reply_queue.name)
    
    result = queue.poll(5, TimeUnit::SECONDS) || 'Timed out'
    # LOGGER.info("RESULT: #{correlation_id} - #{result}")
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

