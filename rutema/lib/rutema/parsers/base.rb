#  Copyright (c) 2007-2011 Vassilis Rizopoulos. All rights reserved.
$:.unshift File.join(File.dirname(__FILE__),'..','..')

module Rutema
  #Is raised when an error is found in a specification
  class ParserError<RuntimeError
  end
  #Base class that bombs out when used.
  #
  #Initialze expects a hash and as a base implementation assigns :logger as the internal logger.
  #
  #By default the internal logger will log to the console if no logger is provided.
  class SpecificationParser
    attr_reader :configuration
    def initialize params
      @configuration=params
      @logger.warn("No system configuration provided to the parser") unless @configuration
      @logger=@configuration[:logger]
      unless @logger
        @logger=Patir.setup_logger
        @configuration[:logger]=@logger
      end
    end
    
    def parse_specification param
      raise ParserError,"not implemented. You should derive a parser implementation from SpecificationParser!"
    end
  end
end