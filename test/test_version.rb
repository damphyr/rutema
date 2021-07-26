# Copyright (c) 2021 Vassilis Rizopoulos. All rights reserved.

# frozen_string_literal: true

require "test/unit"

require_relative "../lib/rutema/version"

module TestRutema
  class TestVersion < Test::Unit::TestCase
    def test_string_rep
      assert_equal("2.0.0", Rutema::Version::STRING)
    end
  end
end
