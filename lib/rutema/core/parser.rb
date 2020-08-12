# Copyright (c) 2007-2020 Vassilis Rizopoulos. All rights reserved.

# frozen_string_literal: true

require_relative 'framework'

module Rutema
  module Parsers
    ##
    # Base class for parsers that raises exceptions if used directly
    #
    # Parser classes should be derived from this class and implement
    # parse_specification and validate_configuration
    class SpecificationParser
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
      # Parse the setup script. By default calls parse_specification
      def parse_setup(param)
        parse_specification(param)
      end

      ##
      # Parse the teardown script. By default calls parse_specification
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
