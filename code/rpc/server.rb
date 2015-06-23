require "march_hare"
require "logger"
require 'pry'
java_import java.util.concurrent.Executors

LOGGER = Logger.new(STDOUT)

def execute_trade(sleep_time)
  sleep sleep_time
  ('A'..'Z').to_a - ['A', 'E', 'I', 'O', 'U']
  "#{Time.now.strftime('%Y%m%d')}-#{(0..6).map { (('A'..'Z').to_a - ['A', 'E', 'I', 'O', 'U']).sample }.join}"
end

conn = MarchHare.connect(:automatically_recover => false, :user => "admin", :password => "Rabbit123")
ch = conn.create_channel
# ch.prefetch = 1
q = ch.queue('rpc.execute_trade')
x = ch.default_exchange
executor = Executors.new_fixed_thread_pool(16)


q.subscribe(:ack => true) do |delivery_info, payload|
  executor.submit do
    # LOGGER.debug("STARTED: #{Thread.current.object_id}")
    begin
      sleep_time = payload.to_f
      r = execute_trade(sleep_time)
      # LOGGER.info("TAG: #{delivery_info.delivery_tag}")
      # LOGGER.info("ID: #{r}, SLEEP: #{sleep_time}")

      ch.ack(delivery_info.delivery_tag)
      LOGGER.info("PUBLISH: #{delivery_info.correlation_id}")
      x.publish("#{r} - #{sleep_time}", :routing_key => delivery_info.reply_to, :correlation_id => delivery_info.correlation_id)
    rescue => e
      LOGGER.error(e)
    end
    # LOGGER.debug("FINISHED")
  end
end  

begin
  puts "Server started"
  sleep
rescue Interrupt => _
  ch.close
  conn.close
end