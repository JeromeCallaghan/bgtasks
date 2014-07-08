require 'clockwork'
require 'logger'
require_relative '../lib/AppSettings'

module Clockwork

  @logger = Logger.new(AppSettings.Get("log-path"), "weekly")
  @logger.level = Logger::INFO

  handler do |job|
    log.info "Running #{job}"
  end

  configure do |config|
    config[:logger] = @logger
  end

  every(AppSettings.Get("secondsCycle").seconds, 'Running') {
    begin
      ChannelBitratePoller::Run(@logger)
    rescue 
      @logger.error $!
    end
   }
end
