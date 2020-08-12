# Copyright (c) 2007-2020 Vassilis Rizopoulos. All rights reserved.

# frozen_string_literal: true

require 'test/unit'
require_relative '../lib/rutema/version'

module TestRutema
  class TestVersion < Test::Unit::TestCase
    def test_version_major
      assert_equal(2, Rutema::Version::MAJOR)
    end

    def test_version_minor
      assert_equal(0, Rutema::Version::MINOR)
    end

    def test_version_tiny
      assert_equal(0, Rutema::Version::TINY)
    end

    def test_version_string
      assert_equal('2.0.0', Rutema::Version::STRING)
    end
  end
end
