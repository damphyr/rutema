#  Copyright (c) 2007-2011 Vassilis Rizopoulos. All rights reserved.
$:.unshift File.join(File.dirname(__FILE__),'..','..')

module Rutema
  #Is raised when an error is found in a specification
  class ParserError<RuntimeError
  end
  #Base class that bombs out when used.
  #
  #By default the internal logger will log to the console if no logger is provided.
  class SpecificationParser
    attr_reader :configuration
    #Expects a hash with at least {:configuration, :logger}
    #
    #At the end validate_configuration is called
    def initialize params
      @configuration=params[:configuration]
      @logger=params[:logger]
      unless @logger
        @logger=Patir.setup_logger
        @configuration||={}
        @configuration[:logger]=@logger
      end
      @logger.warn("No system configuration provided to the parser") unless @configuration
      validate_configuration
    end
    #parses a specification
    def parse_specification param
      raise ParserError,"not implemented. You should derive a parser implementation from SpecificationParser!"
    end
    #parses the setup script. By default calls parse_specification
    def parse_setup param
      parse_specification(param)
    end
    #parses the teardown script. By default calls parse_specification
    def parse_teardown param
      parse_specification(param)
    end
    #The parser stores it's configuration in @configuration
    #
    #To avoid validating the configuration in element_ methods repeatedly, do all configuration validation here
    def validate_configuration
    end
  end
end