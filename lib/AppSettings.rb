##########################################################################
#    FILE NAME:  AppSettings.rb
#
#  DESCRIPTION: Application Settings
#
#        NOTES:
#           Provides access to app configuration
#
#       Copyright (C) 2014  KVH Industries, Inc.
#                 All rights reserved
#
#       Proprietary Notice: This document contains proprietary information of
#       KVH Industries, Inc. and neither the document nor said proprietary
#       information shall be published, reproduced, copied, disclosed or used
#       for any purpose other than the consideration of this document without
#       the expressed written permission of a duly authorized representative
#       of said Company.
#
#       AUTHOR: John Croy, Jerome Callaghan
#
# DATE STARTED: 2014
##########################################################################

require 'yaml'

##################################################################################
#
# Get configuration items from YAML file
#
##################################################################################
module AppSettings extend self    # Singleton
   
  @@settings = nil
  @@CONFIG_FILE_NAME = 'app.config.yml'
  @@environment = ENV['RACK_ENV'] || 'development'

  def environment
    @@environment
  end
  
  def set_environment(env)
    @@environment = env
  end

  def method_missing(name, *args, &block)
    if @@settings == nil  
      @@settings = YAML.load_file(@@CONFIG_FILE_NAME)
    end
    if @@settings[@@environment][name.to_s][args[0].nil?] 
      raise "missing key [#{@@environment}][#{name.to_s}][#{args[0]}] from app.settings"
    end
    @@settings[@@environment][name.to_s][args[0]]
  end  
end
