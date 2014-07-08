require 'logger'
require_relative '../lib/AppSettings'
require_relative 'channel_poller'


@logger = Logger.new(AppSettings.app("log-path"), "weekly")
@logger.level = Logger::INFO

ChannelPoller.Run(@logger)
