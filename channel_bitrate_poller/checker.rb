tsdir = '../../ts-www-2.0'  # TODO change to ts
require 'json'
require 'active_record'
require 'yaml'
require_relative '../lib/AppSettings'
require_relative '../lib/fazzt'
Dir["#{tsdir}/app/models/*.rb"].each {|file| require file }
   
  def get_bitrate(teleport, channelid)
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

environment = AppSettings.environment
dbconfig = YAML.load(File.read('../../ts/config/database.yml'))
ActiveRecord::Base.establish_connection dbconfig[environment]
teleport = Teleport.find_by_title('carlsbad')
puts get_bitrate(teleport, 1100)
puts get_bitrate(teleport, 1112)
puts get_bitrate(teleport, 1113)
