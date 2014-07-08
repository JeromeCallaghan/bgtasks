tsdir = '../../ts-www-2.0'  # TODO change to ts
require 'json'
require 'active_record'
require 'yaml'
require_relative '../lib/fazzt'
Dir["#{tsdir}/app/models/*.rb"].each {|file| require file }

###################################################################
#
# Populate channels
#   Query sendrtransmissions on each teleport
#
###################################################################
class CurrentTransmissionsPoller
   
  ###################################################################
  #
  # Get the beam name, beam channel name from the channel description
  #   <beam>-<beam channel>
  #
  ###################################################################
  def self.get_beam(description)
    beam_name = nil
    bchnl_name = nil
    sepidx = description.index('-')
    if sepidx != nil
      beam_name = description[0, sepidx]
      bchnl_name = description[sepidx+1, description.length-1]
    end
    [beam_name, bchnl_name]
  end
   
  ###################################################################
  #
  # Read from the teleports and populate TS database
  #
  ###################################################################
  def self.Run(logger)

    environment = AppSettings.environment
    dbconfig = YAML.load(File.read('../../ts/config/database.yml'))
    ActiveRecord::Base.establish_connection dbconfig[environment]

    teleports = Teleport.all

    teleports.each do |teleport|

      puts ""; puts""; puts"================== #{teleport.title} ==============================="; puts

      query = "select * from sendtransmissions"
      response = Fazzt.execute_query(teleport.host, query)
      col_ids = response['result']['ColumnIndex']

      response['result']['ResultTable'].each do |row|
    
        transmissionid = [row[col_ids["transmissionid"]]][0]
        # Fazzt returns signed string, convert to unsigned as displayed in Fazzt console
        if transmissionid < 0
          hex_string = (transmissionid % 2**32).to_s(16)
          transmissionid = hex_string.to_i(16)
        end
        transmissionuuid = [row[col_ids["transmissionuuid"]]][0]
        creationdate = [row[col_ids["creationdate"]]][0]
        transmissionsname = [row[col_ids["transmissionname"]]][0]
        filepath = [row[col_ids["filepath"]]][0]
        channelid = [row[col_ids["channelid"]]][0]
        txmodeid = [row[col_ids["txmodeid"]]][0]
        destination = [row[col_ids["destination"]]][0]
        destinationfilename = [row[col_ids["destinationfilename"]]][0]
        filter = [row[col_ids["filter"]]][0]
        usercode = [row[col_ids["usercode"]]][0]
        userstring = [row[col_ids["userstring"]]][0]
        transmissionsize = [row[col_ids["transmissionsize"]]][0]
        transmissionscount = [row[col_ids["transmissioncount"]]][0]
        txbytes = [row[col_ids["txbytes"]]][0]
        senttxbytes = [row[col_ids["senttxbytes"]]][0]
        txpackets = [row[col_ids["txpackets"]]][0]
        senttxpackets = [row[col_ids["senttxpackets"]]][0]
        txduration = [row[col_ids["txduration"]]][0]
        status = [row[col_ids["status"]]][0]
        priority = [row[col_ids["priority"]]][0]

        printf "%12d %30s %70s %6d %6s %8d %8d %8d %8d\n", transmissionid, transmissionuuid, filepath, channelid, status,
              txbytes, senttxbytes, txpackets, senttxpackets
    
        # Beam name and beam channel name come from the channel description <beam>-<beam channel>
#        beam_name, bchnl_name = get_beam description

      end # loop over rows

    end # loop over teleports

  end # of populate method

end # class
