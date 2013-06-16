#  Copyright (c) 2007-2011 Vassilis Rizopoulos. All rights reserved.
$:.unshift File.join(File.dirname(__FILE__),'..','..')

module Rutema
  #Is raised when an error is found in a specification
  class ParserError<RuntimeError
  end
  
  module Parsers  
    #Base class that bombs out when used.
    #
    #Derive your parser class from this class and implement parse_specification and validate_configuration
    class SpecificationParser
      attr_reader :configuration
      def initialize configuration
        @configuration=configuration
        validate_configuration
      end
      #parses a specification
      def parse_specification param
        raise Rutema::ParserError,"not implemented. You should derive a parser implementation from SpecificationParser!"
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
      #To avoid validating the configuration in element_* methods repeatedly, do all configuration validation here
      def validate_configuration
      end
    end
  end
end