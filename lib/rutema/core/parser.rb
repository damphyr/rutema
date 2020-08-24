# Copyright (c) 2007-2020 Vassilis Rizopoulos. All rights reserved.

# frozen_string_literal: true

require_relative 'framework'

module Rutema
  ##
  # Module for the definition of parsers which can be used by Rutema::Engine to
  # parse test specifications
  #
  # _rutema_ comes by default with a parser skeleton class
  # Rutema::Parsers::SpecificationParser from which Rutema::Parsers::XML got
  # derived and implemented as a default parser.
  #
  # The parser to be used is one of the few mandatory configuration options for
  # a _rutema_ invocation. Elaborate documentation about its configuration is
  # available in Rutema::ConfigurationDirectives#parser=
  module Parsers
    ##
    # Base class for parsers that raises exceptions if used directly
    #
    # Derived parser classes (like the default Rutema::Parsers::XML) should
    # implement #parse_specification and #validate_configuration
    class SpecificationParser
      ##
      # The Rutema::Configuration instance of the _rutema_ run creating this
      # parser
      attr_reader :configuration

      def initialize(configuration)
        @configuration = configuration
        @configuration ||= {}
        validate_configuration
      end

      ##
      # Parse a specification
      def parse_specification(_param)
        raise ParserError, \
              'not implemented. You should derive a parser implementation from SpecificationParser!'
      end

      ##
      # Parse the setup script. By default calls #parse_specification
      def parse_setup(param)
        parse_specification(param)
      end

      ##
      # Parse the teardown script. By default calls #parse_specification
      def parse_teardown(param)
        parse_specification(param)
      end

      ##
      # A parser stores its configuration in @configuration
      #
      # To avoid validating the configuration in +element_*+ methods repeatedly,
      # do all configuration validation here.
      #
      # The default implementation of this method does nothing.
      def validate_configuration() end
    end
  end
end
