#  Copyright (c) 2008 Vassilis Rizopoulos. All rights reserved.
$:.unshift File.join(File.dirname(__FILE__),"..")
require 'ostruct'
require 'worker/interfaces'

require 'rubot/gems'

module Rubot
  module Worker
    #this module defines the directives used in the configuration files for Worker
    module Configuration
      #Sets the name with which this worker is known to the Overseer
      def name= definition
        @configuration[:name]=definition
      end
      #The ip address and port for the overseer
      #
      #Required keys are:
      #
      #:ip - the ip address of the Overseer
      #
      #:port - the port the Overseer is listening on
      def overseer= definition
        log("Overseer defined with #{definition_string(definition)}")
        if definition[:ip] && definition[:port]
          @configuration[:overseer]=definition
        else
          raise Patir::ConfigurationException,"missing one of :ip, or :port in the master definition #{definition_string(definition)}"
        end
      end
      #defines the ip address and port the worker listens to for accepting build requests
      #
      #Required keys are:
      #
      #:ip - the ip address to bind
      #
      #:port - the port to listen on
      def endpoint= definition
        log("Interface defined with #{definition_string(definition)}")
        if definition[:ip] && definition[:port]
          @configuration[:endpoint]=definition
        else
          raise Patir::ConfigurationException,"missing one of :ip, or :port in the interface definition #{definition_string(definition)}"
        end
      end
     private
      #Gives back a string of key=value,key=value for a hash
      def definition_string definition
        msg=Array.new
        definition.each{|k,v| msg<<"#{k}=#{v}"}
        return msg.join(",")
      end
      def log msg
        @logger.debug(msg) if @logger
      end
    end
    #Reads and validates Worker configuration files
    class Configurator<Patir::Configurator
      include Configuration
      def initialize config_file,logger=nil
        @configuration={}
        @filename=File.expand_path(config_file)
        super(config_file,logger)
      end
      #maps the configuration hash to the open struct that is required
      #by Worker
      def configuration 
        @logger.debug("Transforming configuration hash")
        @logger.debug(@configuration)
        configuration=OpenStruct.new(@configuration)
        configuration.logger=@logger
        configuration.filename=@filename
        return configuration
      end
    end
  end
end