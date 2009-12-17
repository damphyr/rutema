$:.unshift File.join(File.dirname(__FILE__),"..","lib")
require 'rutema_web/gems'
require 'rutema_web/model'

def time &block
  t = Time.now
  yield
  return Time.now-t
end

ActiveRecord::Base.establish_connection(:adapter  => "sqlite3",:database =>"rutema.db")

runs = nil
t = time do 
  runs = Rutema::Model::Run.find(:all)
end
puts "Got #{runs.size} records in #{t}"

failed = nil
runs.each do |r|
  t = time do
    failed = r.scenarios.select{|sc| !sc.success? && !sc.not_executed? && sc.is_test? }.size
  end
  puts "#{r.id}:#{r.scenarios.size}:#{failed} - #{t}"
  t = time do
    failed = Rutema::Model::Scenario.count(:conditions=>"run_id=#{r.id} AND status = 'error' AND name NOT LIKE '%_teardown' AND name NOT LIKE '%_setup'")
  end
  puts "#{r.id}:#{r.scenarios.size}:#{failed} - #{t}"
end