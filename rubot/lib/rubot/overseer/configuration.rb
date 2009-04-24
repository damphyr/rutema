#  Copyright (c) 2007 Vassilis Rizopoulos. All rights reserved.
require 'ostruct'
require 'rubot/gems'

module Rubot
  module Overseer
    #this module defines the directives used in the configuration files for the Overseer
    module Configuration
      #Sets project wide settings for the projects served by this overseer
      #
      #i.e. {name=>"Rubot Project",:url=>"http://www.rubot.org"}
      #
      #:name - a name for the project (will be used in reports etc.)
      #
      #:url - a url for a project site. This is not the url of this Rubot installation.
      def project= definition
        log("Project defined with #{definition_string(definition)}")
        raise Patir::ConfigurationException,"The projects needs a :name" unless definition[:name]
        @configuration[:projects]||=Array.new
        @configuration[:projects]<<definition
      end    
      #Sets the project's database connection settings
      #
      #At the moment only sqllite is supported, so the only valid key is :filename
      def database= definition
        log("Database defined with #{definition_string(definition)}")
        @configuration[:database]=definition
        raise Patir::ConfigurationException,"Please provide a :filename for the database" unless definition[:filename]
      end    
      #Sets the network parameters for the server.
      # :ip - the ip address to bind
      # :port - the port to bind
      def endpoint= definition
        log("Endpoint defined with #{definition_string(definition)}")
        if definition[:ip] && definition[:port]
          @configuration[:interface]=definition
        else
          raise Patir::ConfigurationException,"missing one of :ip, or :port in the overseer definition #{definition_string(definition)}"
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

    class Configurator<Patir::Configurator
      include Configuration
      def initialize config_file,logger=nil
        @configuration={}
        super(config_file,logger)
      end
      #maps the configuration hash to the open struct that is required
      #by Overseer
      def configuration
        @logger.debug("Transforming configuration hash")
        configuration=OpenStruct.new(@configuration)
        configuration.logger=@logger
        return configuration
      end
    end
  end
end