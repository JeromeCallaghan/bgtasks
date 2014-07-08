require 'json'
require 'rest_client'

###################################################################
#
# Utilities for talking to Fazzt
# TODO log all fazzt calls
#
###################################################################
class Fazzt

  @@host_auths = {}
    
  ##################################################################################
  #
  # Send a request to Fazzt
  #
  ##################################################################################
  def self.send_request_to_fazzt(host, send_data)
    begin
      url = "http://#{host}/ws/json-rpc/InvokeFazztFunction.fzt"
      response = RestClient.post url + '?includes=ChannelLib.fzt,ws/AuthenticateLib.fzt,ws/EchoLib.fzt', send_data.to_json
      response = {} if response.nil?
      JSON.parse response
    rescue
      puts "exception in send_request_to_fazzt #{$!.message}"
    end
  end
  
  ##################################################################################
  #
  # Query the Fazzt database
  #
  ##################################################################################
  def self.execute_query(host, query)
    begin
      send_data = {'method' => 'DBQuery', 'params' => [query], 'id' => 0}
      self.send_request_to_fazzt(host, send_data)
    rescue
      puts "exception in send_request_to_fazzt #{$!.message}"
    end
  end

  ##################################################################################
  #
  # If not logged in to host, log in and save auth token
  #
  ##################################################################################
  def self.authtoken(host)
    unless @@host_auths.has_key? host
      # TODO unanme/pw from config
      send_data = {'method' => 'SignIn', 'params' => ['tsuser', 'tsspanky99', ''], 'id' => 0}
      response = self.send_request_to_fazzt(host, send_data)
      raise "login failed on #{host} #{response['error']}" if response["result"].nil?
      @@host_auths[host] = response["result"]
    end
    @@host_auths[host]
  end

  ##################################################################################
  #
  # Fazzt method ChannelStatsGet
  #
  ##################################################################################
  def self.channel_stats_get(host, channel)
    send_data = {'method' => 'ChannelStatsGet', 'params' => [authtoken(host), channel], 'id' => 0}
    self.send_request_to_fazzt(host, send_data)
  end

  ##################################################################################
  #
  # Fazzt method Echo
  #
  ##################################################################################
  def self.echo(host, text)
    send_data = {'method' => 'Echo', 'params' => [text], 'id' => 0}
    self.send_request_to_fazzt(host, send_data)
  end
end
