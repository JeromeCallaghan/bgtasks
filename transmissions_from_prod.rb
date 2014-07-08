tsdir = '../ts-www-2.0'  # TODO change to ts
require 'active_record'
Dir["#{tsdir}/app/models/*.rb"].each {|file| require file }

# Get the last date in development
ActiveRecord::Base.establish_connection({ 
            'adapter'  => 'mysql2', 
            'database' => 'ts-dev',
            'host'     => 'localhost',
            'username' => 'root',
            'password' => '',
            'timeout'  => 5000
      })
result = Transmission.find_by_sql("select dt_started from transmissions order by dt_started desc limit 1")
dt_started = result[0].dt_started
puts dt_started

# Get the records in producdtion since that date
ActiveRecord::Base.establish_connection({ 
            'adapter'  => 'mysql2', 
            'database' => 'ts',
            'host'     => 'ts1.dallas.ops.kvh.com',
            'username' => 'root',
            'password' => '',
            'timeout'  => 5000
      })
result = Transmission.find_by_sql("select * from transmissions where dt_started > '#{dt_started}'")
newrows = []
result.each do |row|
  newrows << {id: row.id, uuid: row.uuid, status: row.status, dt_started: row.dt_started, package_file_id: row.package_file_id}
end

# insert the new rows into the dev database
ActiveRecord::Base.establish_connection({ 
            'adapter'  => 'mysql2', 
            'database' => 'ts-dev',
            'host'     => 'localhost',
            'username' => 'root',
            'password' => '',
            'timeout'  => 5000
      })
newrows.each do |row|
  trans = Transmission.new(uuid: row[:uuid], status: row[:status], dt_started: row[:dt_started], package_file_id: row[:package_file_id])
  trans.save
  puts "#{trans.id} #{trans.uuid} #{trans.status} #{trans.dt_started} #{trans.package_file_id}"
end