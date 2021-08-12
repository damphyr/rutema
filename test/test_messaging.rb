#  Copyright (c) 2021 Markus Prasser. All rights reserved.

require_relative "../lib/rutema/core/framework"

require "test/unit"

module TestRutema
  ##
  # Class without a member +queue+ that fails upon calls to Rutema::Messaging
  # methods
  #
  # This class is a helper for the TestMessaging class.
  class MessagingFailure
    include Rutema::Messaging
  end

  ##
  # Class with a member +queue+ to test calls to Rutema::Messaging methods
  #
  # This class is a helper for the TestMessaging class.
  class MessagingTester
    include Rutema::Messaging

    ##
    # The queue the Rutema::Messaging methods should insert their messages into
    attr_reader :queue

    ##
    # Initialize the instance and its +queue+ member
    def initialize
      @queue = Queue.new
    end
  end

  ##
  # Verify functionality of the Rutema::Messaging module
  #
  # This class utilizes MessagingFailure and MessagingTester for its tests.
  class TestMessaging < Test::Unit::TestCase
    ##
    # Verify that Rutema::Messaging methods fail if called on a class without
    # a +queue+ member
    def test_fail_without_queue
      inst = MessagingFailure.new
      assert_raises(NoMethodError) do
        inst.error("some_identifier", "a message")
      end
      assert_raises(NoMethodError) do
        inst.message("some information")
      end
      assert_raises(NoMethodError) do
        inst.message("status" => "ok", :test => "test A")
      end
    end

    ##
    # Verify functionality of Rutema::Messaging#error
    def test_error_push
      inst = MessagingTester.new
      assert(inst.queue.empty?)
      before = Time.now
      inst.error("another_identifier", "Oh oh, that look's bad")
      after = Time.now
      assert_equal(inst.queue.size, 1)
      err_msg = inst.queue.pop
      assert_instance_of(Rutema::ErrorMessage, err_msg)
      assert_equal("another_identifier", err_msg.test)
      assert_equal("Oh oh, that look's bad", err_msg.text)
      assert(before < err_msg.timestamp && after > err_msg.timestamp)
    end

    ##
    # Verify functionality of Rutema::Messaging#message if a hash without both
    # the fields +"status"+ and +:test+ is being passed
    def test_hash_message_push
      inst = MessagingTester.new
      assert(inst.queue.empty?)
      before = Time.now
      inst.message(:a => "a", :b => "b")
      after = Time.now
      assert_equal(inst.queue.size, 1)
      msg = inst.queue.pop
      assert_instance_of(Rutema::Message, msg)
      assert_equal("", msg.test)
      assert_equal("", msg.text)
      assert(before < msg.timestamp && after > msg.timestamp)
    end

    ##
    # Verify functionality of Rutema::Messaging#message if a hash with both the
    # fields +"status"+ and +:test+ is being passed
    def test_hash_runner_message_push
      inst = MessagingTester.new
      assert(inst.queue.empty?)
      before = Time.now
      inst.message(:a => "a", :b => "b", "status" => "great", :test => "test B")
      after = Time.now
      assert_equal(inst.queue.size, 1)
      msg = inst.queue.pop
      assert_instance_of(Rutema::RunnerMessage, msg)
      assert_equal("test B", msg.test)
      assert_equal("great", msg.status)
      assert_equal("", msg.text)
      assert(before < msg.timestamp && after > msg.timestamp)
    end

    ##
    # Verify functionality of Rutema::Messaging#message if a string is given as
    # a message
    def test_string_push
      inst = MessagingTester.new
      assert(inst.queue.empty?)
      before = Time.now
      inst.message("some random information")
      after = Time.now
      assert_equal(inst.queue.size, 1)
      msg = inst.queue.pop
      assert_instance_of(Rutema::Message, msg)
      assert_equal("", msg.test)
      assert_equal("some random information", msg.text)
      assert(before < msg.timestamp && after > msg.timestamp)
    end
  end
end
