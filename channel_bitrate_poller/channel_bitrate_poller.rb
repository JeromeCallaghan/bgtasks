tsdir = '../../ts-www-2.0'  # TODO change to ts
require 'json'
require 'active_record'
require 'yaml'
require_relative '../lib/AppSettings'
require_relative '../lib/fazzt'
Dir["#{tsdir}/app/models/*.rb"].each {|file| require file }

###################################################################
#
#
###################################################################
class ChannelBitratePoller  
   
  def self.get_bitrate(teleport, channelid)
    bitrate = 0
    begin
      response = Fazzt.channel_stats_get(teleport.host, channelid)
      result = response['result']
      bitrate = result['Bandwidth']
    rescue => detail
      puts $!.message
      puts detail.backtrace.join("\n")
    end
    bitrate * 8
  end

  ###################################################################
  #
  #
  ###################################################################
  def self.do_teleport_subchannel(logger, teleport, subchannel)
    [teleport, subchannel, get_bitrate(teleport, subchannel)]
  end  

  ###################################################################
  #
  #
  ###################################################################
  def self.do_teleport_channel(logger, teleport, channel)
    bitrates = {}
    bitrates[channel.id_channel] = get_bitrate(teleport, channel.id_channel)
    subchannels = Channel.find_by_sql("select * from channels where teleport_id=#{teleport.id} and id_channel_parent=#{channel.id_channel}")
    threads = []
    subchannels.each do |subchannel|
      threads << Thread.new { do_teleport_subchannel logger, teleport, subchannel.id_channel }
    end
    
    subchannel_bitrates = []
    threads.each do |thread|
      thread.join
      teleport, subchannel, bitrate = thread.value
      bitrates[subchannel] = bitrate
    end
    bitrates
  end  
   
  ###################################################################
  #
  #
  ###################################################################
  def self.do_teleport(logger, teleport)
    channels = Channel.find_by_sql("select * from channels where teleport_id=#{teleport.id} and id_channel_parent=0")
    bitrates = {}
    channels.each do |channel|
      bitrates.merge!(do_teleport_channel(logger, teleport, channel))
    end
    {teleport: {id: teleport.id, title: teleport.title}, bitrates: bitrates}
  end
   
  ###################################################################
  #
  #
  ###################################################################
  def self.Run(logger)

    environment = AppSettings.environment
    dbconfig = YAML.load(File.read('../../ts/config/database.yml'))
    ActiveRecord::Base.establish_connection dbconfig[environment]

    teleports = Teleport.all

    threads = []
    teleports.each do |teleport|
      threads << Thread.new { do_teleport(logger, teleport) }
    end
    threads.each do |thread|
      thread.join
      result = thread.value
      teleport_id = result[:teleport][:id]
      teleport_title = result[:teleport][:title]
      bitrates = result[:bitrates]
      bitrates.each do |subchannel, bitrate|
        channel = Channel.find_by_teleport_id_and_id_channel(teleport_id, subchannel)
        channel.bitrate = bitrate
        channel.save
     end
    end

  end # of populate method

end # class
