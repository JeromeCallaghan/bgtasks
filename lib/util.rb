require 'active_record'
require 'yaml'
require_relative './AppSettings'

module Util

  def self.tsdbconnect
    environment = AppSettings.environment
    dbconfig = YAML.load(File.read('../../ts/config/database.yml'))
    ActiveRecord::Base.establish_connection dbconfig[environment]
    teleports = Teleport.all
  end
  
end