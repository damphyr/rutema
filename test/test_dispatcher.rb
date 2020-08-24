# Copyright (c) 2007-2020 Vassilis Rizopoulos. All rights reserved.

# frozen_string_literal: true

require 'test/unit'
require 'mocha/test_unit'

require_relative '../lib/rutema/core/dispatcher'

module TestRutema
  ##
  # Test Rutema::Dispatcher
  class TestDispatcher < Test::Unit::TestCase
    ##
    # Test initialization
    def test_initialize
      mock_config = mock
      mock_config.expects(:reporters).twice.returns({})
      queue = Queue.new
      assert_nothing_raised { Rutema::Dispatcher.new(queue, mock_config) }
    end

    ##
    # Test subscribing to messages
    def test_subscribe
      mock_config = mock
      mock_config.expects(:reporters).twice.returns({})
      queue = Queue.new
      dispatcher = Rutema::Dispatcher.new(queue, mock_config)

      out_queue_a = dispatcher.subscribe(:test_ident_a)
      assert_instance_of(Queue, out_queue_a)

      out_queue_b = dispatcher.subscribe(:test_ident_b)
      assert_instance_of(Queue, out_queue_b)

      # ToDo(markuspg) Wouldn't it be better if duplicate subscription failed?
      out_queue_c = dispatcher.subscribe(:test_ident_a)
      assert_instance_of(Queue, out_queue_c)
    end
  end
end
