require 'sinatra'
require "thread"
require "march_hare"
require 'pry'

require 'logger'
LOGGER = Logger.new(STDOUT)

class ExecuteCommand
  attr_reader :reply_queue, :lock, :condition, :correlation_id, :default_exchange
  attr_accessor :response

  def initialize(ch, server_queue)
    @default_exchange = ch.default_exchange
    @server_queue = server_queue
    @reply_queue = ch.queue("", :exclusive => true)

    @lock = Mutex.new
    @condition = ConditionVariable.new
    @correlation_id = java.util.UUID.randomUUID().to_s
    that = self

    @reply_queue.subscribe do |payload|
      # if properties[:correlation_id] == that.correlation_id
        that.response = payload
        that.lock.synchronize{that.condition.signal}
      # end
    end
  end

  def call(value)
    @default_exchange.publish(value.to_s,
      :routing_key    => @server_queue,
      :correlation_id => correlation_id,
      :reply_to       => @reply_queue.name)
    
    lock.synchronize { condition.wait(lock) }
    response + "\n"
  end
end

get '/execute_trade' do
  conn = MarchHare.connect(:automatically_recover => false, :user => "admin", :password => "Rabbit123")
  ch = conn.create_channel

  client = ExecuteCommand.new(ch, 'rpc.execute_trade')
  begin
    LOGGER.debug('EXECUTING')
    response = client.call((params[:sleep] || 5).to_s)
  ensure
    ch.close
    conn.close
  end
end