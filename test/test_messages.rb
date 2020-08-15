# Copyright (c) 2007-2020 Vassilis Rizopoulos. All rights reserved.

# frozen_string_literal: true

require 'test/unit'
require 'mocha/test_unit'

require_relative '../lib/rutema/core/framework'

module TestRutema
  class TestErrorMessage < Test::Unit::TestCase
    def test_initialize_default
      # Test initialization
      timestamp_before = Time.now
      msg = assert_nothing_raised do
        Rutema::ErrorMessage.new({})
      end
      timestamp_after = Time.now

      # Verify created instance
      assert_equal('', msg.test)
      assert_equal('', msg.text)
      assert((timestamp_before < msg.timestamp) \
             && (timestamp_after > msg.timestamp))
    end

    def test_initialize_full
      # Test initialization
      timestamp = Time.now
      msg = assert_nothing_raised do
        Rutema::ErrorMessage.new({ test: 'Msg Init Example Test',
                                   text: 'Some hypothetical message text',
                                   timestamp: timestamp })
      end

      # Verify created instance
      assert_equal('Msg Init Example Test', msg.test)
      assert_equal('Some hypothetical message text', msg.text)
      assert_equal(timestamp, msg.timestamp)
    end

    def test_stringification
      # Create and verify minimal message
      msg = Rutema::ErrorMessage.new({})
      assert_equal('ERROR - ', msg.to_s)

      # Create and verify message only with text given
      msg = Rutema::ErrorMessage.new({ text: 'Some sample text' })
      assert_equal('ERROR - Some sample text', msg.to_s)

      # Create and verify message with test and text given
      msg = Rutema::ErrorMessage.new({ test: 'Msg Test', text: 'Some sample text' })
      assert_equal('ERROR - Msg Test Some sample text', msg.to_s)

      # Create and verify message with all attributes set
      msg = Rutema::ErrorMessage.new({ test: 'Msg Test', text: 'Some sample text',
                                       timestamp: Time.now })
      assert_equal('ERROR - Msg Test Some sample text', msg.to_s)
    end
  end

  class TestMessage < Test::Unit::TestCase
    def test_initialize_default
      # Test initialization
      timestamp_before = Time.now
      msg = assert_nothing_raised do
        Rutema::Message.new({})
      end
      timestamp_after = Time.now

      # Verify created instance
      assert_equal('', msg.test)
      assert_equal('', msg.text)
      assert((timestamp_before < msg.timestamp) \
             && (timestamp_after > msg.timestamp))
    end

    def test_initialize_full
      # Test initialization
      timestamp = Time.now
      msg = assert_nothing_raised do
        Rutema::Message.new({ test: 'Msg Init Example Test',
                              text: 'Some hypothetical message text',
                              timestamp: timestamp })
      end

      # Verify created instance
      assert_equal('Msg Init Example Test', msg.test)
      assert_equal('Some hypothetical message text', msg.text)
      assert_equal(timestamp, msg.timestamp)
    end

    def test_stringification
      # Create and verify minimal message
      msg = Rutema::Message.new({})
      assert_equal('', msg.to_s)

      # Create and verify message only with text given
      msg = Rutema::Message.new({ text: 'Some sample text' })
      assert_equal('Some sample text', msg.to_s)

      # Create and verify message with test and text given
      msg = Rutema::Message.new({ test: 'Msg Test', text: 'Some sample text' })
      assert_equal('Msg Test Some sample text', msg.to_s)

      # Create and verify message with all attributes set
      msg = Rutema::Message.new({ test: 'Msg Test', text: 'Some sample text',
                                  timestamp: Time.now })
      assert_equal('Msg Test Some sample text', msg.to_s)
    end
  end
end
