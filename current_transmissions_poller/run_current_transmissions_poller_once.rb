require 'logger'
require_relative '../lib/AppSettings'
require_relative 'current_transmissions_poller'


@logger = Logger.new(AppSettings.app("log-path"), "weekly")
@logger.level = Logger::INFO

CurrentTransmissionsPoller.Run(@logger)
