require 'logger'
require_relative '../lib/AppSettings'
require_relative 'transmissions_poller'


@logger = Logger.new(AppSettings.app("log-path"), "weekly")
@logger.level = Logger::INFO

TransmissionsPoller.Run(@logger)
