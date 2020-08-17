# Copyright (c) 2007-2020 Vassilis Rizopoulos. All rights reserved.

# frozen_string_literal: true

require 'test/unit'
require 'mocha/test_unit'

require_relative '../lib/rutema/core/framework'

module TestRutema
  ##
  # Test Rutema::ReportTestState
  class TestReportTestState < Test::Unit::TestCase
    def test_initialize
      # Prepare mock
      mock_message = mock
      mock_message.expects(:duration).returns(325)
      mock_message.expects(:is_special).returns(false)
      mock_message.expects(:status).returns(:some_status)
      mock_message.expects(:test).returns('Example test')
      timestamp = Time.now
      mock_message.expects(:timestamp).returns(timestamp)

      # Test initialization
      report_state = assert_nothing_raised do
        Rutema::ReportTestState.new(mock_message)
      end

      # Verify created instance
      assert_equal(325, report_state.duration)
      assert_equal(false, report_state.is_special)
      assert_equal(:some_status, report_state.status)
      assert_equal('Example test', report_state.test)
      assert_equal(timestamp, report_state.timestamp)
      assert_equal(1, report_state.steps.size)
      assert_equal(mock_message, report_state.steps[0])
    end

    def test_insertion
      # Prepare mock and create ReportTestState instance
      mock_message_a = mock
      mock_message_a.expects(:duration).returns(41)
      mock_message_a.expects(:is_special).returns(false)
      mock_message_a.expects(:status).returns(:a_status)
      mock_message_a.expects(:test).returns('Example test A')
      timestamp = Time.now
      mock_message_a.expects(:timestamp).returns(timestamp)
      report_state = Rutema::ReportTestState.new(mock_message_a)

      # Test insertion
      mock_message_b = mock
      mock_message_b.expects(:duration).returns(29)
      mock_message_b.expects(:status).returns(:b_status)
      mock_message_b.expects(:test).returns('Example test A')
      report_state << mock_message_b
      assert_equal(70, report_state.duration)
      assert_equal(:b_status, report_state.status)
      assert_equal('Example test A', report_state.test)
      assert_equal(timestamp, report_state.timestamp)
      assert_equal(2, report_state.steps.size)
      assert_equal([mock_message_a, mock_message_b], report_state.steps)

      mock_message_c = mock
      mock_message_c.expects(:duration).returns(84)
      mock_message_c.expects(:status).returns(:c_status)
      mock_message_c.expects(:test).returns('Example test A')
      report_state << mock_message_c
      assert_equal(154, report_state.duration)
      assert_equal(:c_status, report_state.status)
      assert_equal('Example test A', report_state.test)
      assert_equal(timestamp, report_state.timestamp)
      assert_equal(3, report_state.steps.size)
      assert_equal([mock_message_a, mock_message_b, mock_message_c],
                   report_state.steps)

      mock_message_d = mock
      mock_message_d.expects(:duration).returns(24)
      mock_message_d.expects(:status).returns(:d_status)
      mock_message_d.expects(:test).returns('Example test A')
      report_state << mock_message_d
      assert_equal(178, report_state.duration)
      assert_equal(:d_status, report_state.status)
      assert_equal('Example test A', report_state.test)
      assert_equal(timestamp, report_state.timestamp)
      assert_equal(4, report_state.steps.size)
      assert_equal([mock_message_a, mock_message_b,
                    mock_message_c, mock_message_d],
                   report_state.steps)
    end
  end
end
