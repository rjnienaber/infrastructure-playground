require "march_hare"
require "logger"
require 'pry'
java_import java.util.concurrent.Executors

LOGGER = Logger.new(STDOUT)

def execute_trade(sleep_time)
  sleep sleep_time
  "#{Time.now.strftime('%Y%m%d')}-#{(0..6).map { (('A'..'Z').to_a - ['A', 'E', 'I', 'O', 'U']).sample }.join}"
end

settings = {:user => "admin", :password => "Rabbit123", :port => 5673}
LOGGER.info("SETTINGS: #{settings}")

conn = MarchHare.connect(settings)
ch = conn.create_channel
q = ch.queue('rpc.execute_trade', :durable => true, :auto_delete => false)
x = ch.default_exchange
executor = Executors.new_fixed_thread_pool(16)

q.subscribe(:ack => true) do |meta_data, payload|
  executor.submit do
    # LOGGER.debug("STARTED: #{Thread.current.object_id}")
    begin
      sleep_time = payload.to_f
      r = execute_trade(sleep_time)
      LOGGER.info("ID: #{r}, SLEEP: #{sleep_time}")

      ch.ack(meta_data.delivery_tag)
      # LOGGER.info("PUBLISH: #{meta_data.correlation_id}")
      x.publish("#{r} - #{sleep_time}", :routing_key => meta_data.reply_to)
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