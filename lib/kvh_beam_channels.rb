tsdir = '../ts-www-2.0'  # TODO change to ts
require 'active_record'
require_relative 'util'
require_relative 'fazzt'
Dir["#{tsdir}/app/models/*.rb"].each {|file| require file }

##################################################################################
#
# Represents KVH Beam Channels
#   When looping over KvhBeamChannels, order will be teleport, beam, beam channel
#
##################################################################################
class KvhBeamChannels
  
  @@beam_channels = nil

  
  #####################################################################
  #
  # Parse <beam name>-<beam channel name>
  #
  #####################################################################
  def self.get_beam(description, bandwidth)
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
  
  #####################################################################
  #
  # Constructor - build array of BeamChannels from teleports Fazzt data
  #
  #####################################################################
  def self.get_beam_channels
    Util::tsdbconnect # TODO this should happen in app
    teleports = Teleport.all
    teleports.each do |teleport|
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

        # We only care about transmit channels and not subchannels
        if rxtxtype != 'T' || bandwidth == 0 then next end
    
        # Beam name and beam channel name come from the channel description <beam>-<beam channel>
        beam_name, bchnl_name = get_beam description, bandwidth
        
        @@beam_channels << {name: bchnl_name, beam: {name: beam_name, teleport: {title: teleport.title}}, id_channel: channelid,
                            status: status, configured_bitrate: bandwidth, bitrate: ondemandbandwidth}
      end # rows
    end # teleports
  end # initialize
  
  def self.beam_channels
    if @@beam_channels.nil?
      @@beam_channels = []
      self.get_beam_channels
    end
    @@beam_channels
  end
end

#KvhBeamChannels.beam_channels.each do |beam_channel|
  puts KvhBeamChannels.beam_channels.to_xml(:root => 'beam_channel_settings')
#end