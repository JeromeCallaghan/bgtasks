tsdir = '../../ts-www-2.0'  # TODO change to ts
require 'json'
require 'active_record'
require 'yaml'
require_relative '../lib/fazzt'
require_relative '../lib/AppSettings'
Dir["#{tsdir}/app/models/*.rb"].each {|file| require file }

def get_beam(description, bandwidth)
  beam_name = nil
  bchnl_name = nil
  if bandwidth != 0
    sepidx = description.index('-')
    if sepidx != nil
      beam_name = description[0, sepidx]
      bchnl_name = description[sepidx+1, description.length-1]
    end
  end
  [beam_name, bchnl_name]
end


environment = AppSettings.environment
dbconfig = YAML.load(File.read('../../ts/config/database.yml'))
ActiveRecord::Base.establish_connection dbconfig[environment]

teleports = Teleport.all

teleports.each do |teleport|

  puts ""; puts""; puts"================== #{teleport.title} ==============================="; puts
  printf "%-7s %-10s %4s %7s %6s\n", 'beam', 'bchan', 'chan', 'bandwidth', 'status'

  query = "select * from channels order by channelid"
  response = Fazzt.execute_query(teleport.host, query)
  col_ids = response['result']['ColumnIndex']

  response['result']['ResultTable'].each do |row|
    
    channelid = [row[col_ids["channelid"]]][0]
    rxtxtype = [row[col_ids["rxtxtype"]]][0]
    bandwidth = [row[col_ids["bandwidth"]]][0]
    maxbandwidth = [row[col_ids["maxbandwidth"]]][0]
    minbandwidth = [row[col_ids["minbandwidth"]]][0]
    ondemandbandwidth = [row[col_ids["ondemandbandwidth"]]][0]
    priority = [row[col_ids["priority"]]][0]
    parent = [row[col_ids["parent"]]][0]
    rootchannel = [row[col_ids["rootchannel"]]][0]
    hostid = [row[col_ids["hostid"]]][0]
    description = [row[col_ids["description"]]][0]
    status = [row[col_ids["status"]]][0]

    # Only care about transmit channels
    if rxtxtype != 'T' then next end
      
    # Only care about the top-level channels
    if bandwidth == 0 then next end
    
    # Beam name and beam channel name come from the channel description <beam>-<beam channel>
    beam_name, bchnl_name = get_beam description, bandwidth
    printf "%-7s %-10s %4d %7d %6s\n", 
            beam_name, bchnl_name, channelid, bandwidth, status
    
        # Beam name and beam channel name come from the channel description <beam>-<beam channel>
#        beam_name, bchnl_name = get_beam description

  end # loop over rows

end # loop over teleports
