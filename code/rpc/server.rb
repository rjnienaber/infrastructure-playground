require "march_hare"
require "logger"

LOGGER = Logger.new(STDOUT)

def execute_trade(sleep_time)
  sleep sleep_time
  ('A'..'Z').to_a - ['A', 'E', 'I', 'O', 'U']
  "#{Time.now.strftime('%Y%m%d')}-#{(0..6).map { (('A'..'Z').to_a - ['A', 'E', 'I', 'O', 'U']).sample }.join}"
end

conn = MarchHare.connect(:automatically_recover => false, :user => "admin", :password => "Rabbit123", :executor_factory => Proc.new { MarchHare::ThreadPools.fixed_of_size(16) })
ch = conn.create_channel
# ch.prefetch = 1
q = ch.queue('rpc.execute_trade')
x = ch.default_exchange

q.subscribe(:blocking => false, :ack => true, :executor => MarchHare::ThreadPools.fixed_of_size(16)) do |delivery_info, payload|
  ch.ack(delivery_info.delivery_tag)
  LOGGER.debug("STARTED: #{Thread.current.object_id}")
  begin
    sleep_time = payload.to_f
    r = execute_trade(sleep_time)

    LOGGER.info("TRADE ID: #{r}, SLEEP: #{sleep_time}")

    x.publish(r.to_s, :routing_key => delivery_info.reply_to, :correlation_id => delivery_info.correlation_id)
  rescue => e
    LOGGER.error(e)
  end
  LOGGER.debug("FINISHED")
end  

begin
  puts "Server started"
  sleep
rescue Interrupt => _
  ch.close
  conn.close
end