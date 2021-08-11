#  Copyright (c) 2007-2021 Vassilis Rizopoulos. All rights reserved.

require_relative 'framework'

module Rutema
  ##
  # Module for the definition of classes for the parsing of test specifications
  module Parsers
    ##
    # Base class for parser implementations
    #
    # This class itself is not operational but only throws exceptions upon
    # invocations of its +parse_*+ methods. Its sole purpose is to define a
    # common interface for parser classes.
    #
    # Derived classes should implement at least the parse_specification and
    # validate_configuration methods.
    class SpecificationParser
      ##
      # The Configuration instance passed to and used by the initializer
      attr_reader :configuration

      ##
      # Initialize a new instance internally storing and validating the passed
      # Configuration instance
      def initialize configuration
        @configuration=configuration
        @configuration||={}
        validate_configuration
      end

      ##
      # Parse a test specification
      #
      # The passed argument can either be the path to a test specification file
      # or the test specification itself.
      def parse_specification param
        raise ParserError,"not implemented. You should derive a parser implementation from SpecificationParser!"
      end

      ##
      # Parse a setup specification
      #
      # This calls #parse_specification by default.
      def parse_setup param
        parse_specification(param)
      end

      ##
      # Parse a teardown specification
      #
      # This calls #parse_specification by default.
      def parse_teardown param
        parse_specification(param)
      end

      ##
      # Validate the Configuration instance which is stored by the parser
      # internally
      #
      # To avoid validating the configuration in element_* methods repeatedly, do all configuration validation here
      def validate_configuration
      end
    end
  end
end
