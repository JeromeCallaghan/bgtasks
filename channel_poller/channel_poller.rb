tsdir = '../../ts-www-2.0'  # TODO change to ts
require 'json'
require 'active_record'
require 'yaml'
require_relative '../lib/fazzt'
Dir["#{tsdir}/app/models/*.rb"].each {|file| require file }

###################################################################
#
# Populate channels
#   Query channel information from each teleport
#   And populate the channels
# TODO , beams, and beam_channels tables
#   Delete channels no longer configured at a teleport
#
###################################################################
class ChannelPoller

   @existing_channels = []
   
  ###################################################################
  #
  # Get the existing channels in the TS database
  #
  ###################################################################
  def self.get_existing_channels
    # Get the current channels so we can delete any not found during processing
    channels = Channel.all
    channels.each do |channel|
      @existing_channels << {id: channel.id, found: false, teleport_id: channel.teleport_id, id_channel: channel.id_channel } 
    end
  end
   
  ###################################################################
  #
  # Mark existing channels found so can delete those not found
  #
  ###################################################################
  def self.check_existing teleport_id, id_channel
    found = false;
    @existing_channels.each do |existing_channel|
      if existing_channel[:teleport_id] == teleport_id && existing_channel[:id_channel] == id_channel
        existing_channel[:found] = true
        found = true
      end
    end
  end
   
  ###################################################################
  #
  # Delete existing channels not found
  #
  ###################################################################
  def self.delete_existing_channels_not_found
    @existing_channels.each do |existing_channel|
      if existing_channel[:found] != true
        Channel.delete(existing_channel[:id])
      end
    end
  end
   
  ###################################################################
  #
  # Get the beam name, beam channel name from the channel description
  #   <beam>-<beam channel>
  #
  ###################################################################
=begin TODO
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
=end
   
  ###################################################################
  #
  # Read from the teleports and populate TS database
  #
  ###################################################################
  def self.Run(logger)

    environment = AppSettings.environment
    dbconfig = YAML.load(File.read('../../ts/config/database.yml'))
    ActiveRecord::Base.establish_connection dbconfig[environment]

    get_existing_channels
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

        # We only care about transmit channels
        if rxtxtype != 'T' then next end
    
        # Check if existing so we can delete existing not found
       check_existing teleport.id, channelid
    
        # Beam name and beam channel name come from the channel description <beam>-<beam channel>
# TODO        beam_name, bchnl_name = get_beam description

        # if channel is already in the database, check if need to update, else create new channel
        #   create or update associated beam / beam channel also
        chnl = Channel.find_by_teleport_id_and_id_channel(teleport.id, channelid)
        if(chnl == nil)
          chnl = Channel.new(teleport_id: teleport.id, id_channel: channelid, bitrate: 0,  bandwidth: bandwidth,
                              maxbandwidth: maxbandwidth, minbandwidth: minbandwidth, ondemandbandwidth: ondemandbandwidth,
                              priority: priority, rootchannel: rootchannel, description: description, status: status,
                              id_channel_parent: parent)
          chnl.save
          logger.info("Create channel teleport=#{teleport.title} channel=#{channelid}")
=begin TODO
          if(beam_name != nil)
            beam = Beam.new(channel_id: chnl.id, name: beam_name)
            beam.save
            beam_channel = BeamChannel.new(beam_id: beam.id, name: bchnl_name)
            beam_channel.save
          end
=end
        
        else # Channel already exists, check for changes
          has_changes = false
          if chnl.teleport_id != teleport.id then has_changes = true; chnl.teleport_id = teleport.id end
          if chnl.id_channel != channelid then has_changes = true; chnl.channelid = channelid end
          if chnl.bandwidth != bandwidth then has_changes = true; chnl.bandwidth = bandwidth end
          if chnl.maxbandwidth != maxbandwidth then has_changes = true; chnl.maxbandwidth = maxbandwidth end
          if chnl.minbandwidth != minbandwidth then has_changes = true; chnl.minbandwidth = minbandwidth end
          if chnl.ondemandbandwidth != ondemandbandwidth then has_changes = true; chnl.ondemandbandwidth = ondemandbandwidth end
          if chnl.priority != priority then has_changes = true; chnl.priority = priority end
          if chnl.rootchannel != rootchannel then has_changes = true; chnl.rootchannel = rootchannel end
          if chnl.description != description then has_changes = true; chnl.description = description end
          if chnl.status != status then has_changes = true; chnl.status = status end
          if chnl.id_channel_parent != parent then has_changes = true; chnl.id_channel_parent = parent end
          if has_changes
            chnl.save
           end
# TODO if do beam/beam channel, need to check update
        end

      end # loop over rows

    end # loop over teleports
 
    delete_existing_channels_not_found

  end # of populate method

end # class
