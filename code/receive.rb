#!/usr/bin/env ruby
# encoding: utf-8

require "bunny"

file_name = ARGV[0]
puts "WRITING TO '#{file_name}'"
conn = Bunny.new(:automatically_recover => false, :user => "admin", :password => "Rabbit123")
conn.start

ch   = conn.create_channel
q    = ch.queue("hello")

file = File.open(file_name, 'wb')
begin
  puts " [*] Waiting for messages. To exit press CTRL+C"
  q.subscribe(:block => true) do |delivery_info, properties, body|
    file.write("#{body}\n")
  end
rescue Interrupt => _
  conn.close
  file.close

  exit(0)
end
