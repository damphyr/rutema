# Copyright (c) 2021 Vassilis Rizopoulos. All rights reserved.

# frozen_string_literal: true

require "test/unit"

require_relative "../lib/rutema/version"

module Rutema
  ##
  # Module for the verification of the functionality of the Rutema gem
  module Test
    ##
    # Verify functionality of the Rutema::Version module
    class Version < ::Test::Unit::TestCase
      ##
      # Verify that the string representation is properly created
      def test_string_representation
        assert_equal("2.0.0", Rutema::Version::STRING)
      end
    end
  end
end
