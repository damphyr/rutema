# Copyright (c) 2007-2020 Vassilis Rizopoulos. All rights reserved.

# frozen_string_literal: true

require 'test/unit'
require 'mocha/test_unit'

require_relative '../lib/rutema/core/framework'

##
# Facilitate testing with a Rutema::Messaging based class
class TestClass
  include Rutema::Messaging

  attr_reader :queue

  def initialize
    @queue = Queue.new
  end
end

module TestRutema
  ##
  # Test Rutema::Messaging
  class TestMessaging < Test::Unit::TestCase
    def test_error
      # Create a class to use for testing
      test_class = TestClass.new

      # Verify that the queue is empty
      assert(test_class.queue.empty?)

      # Insert a few ErrorMessage instances into the queue
      timestamps_after = []
      timestamps_before = []
      (0..44).step(1).each do |idx|
        timestamps_before[idx] = Time.now
        test_class.error("Example Test #{idx}", "Oops #{idx}")
        timestamps_after[idx] = Time.now
      end

      # Verify the queue and its contents
      assert_equal(45, test_class.queue.size)
      (0..44).step(1).each do |idx|
        msg = test_class.queue.pop
        assert_instance_of(Rutema::ErrorMessage, msg)
        assert_equal("Example Test #{idx}", msg.test)
        assert_equal("Oops #{idx}", msg.text)
        assert((timestamps_before[idx] < msg.timestamp) \
               && (timestamps_after[idx] > msg.timestamp))
      end
    end

    def test_message_hash
      # Create a class to use for testing
      test_class = TestClass.new

      # Verify that the queue is empty
      assert(test_class.queue.empty?)

      # Insert interchangingly a Message and a RunnerMessage into the queue
      timestamps_after = []
      timestamps_before = []
      (0..31).step(1).each do |idx|
        timestamps_before[idx] = Time.now
        test_class.message({ text: "Example message #{idx * 2}" })
        test_class.message({ 'status' => :not_started,
                             test: 'Example Test',
                             text: "Example message #{idx * 2 + 1}" })
        timestamps_after[idx] = Time.now
      end

      # Verify the queue and its contents
      assert_equal(64, test_class.queue.size)
      (0..31).step(1).each do |idx|
        msg = test_class.queue.pop
        assert_instance_of(Rutema::Message, msg)
        assert_equal('', msg.test)
        assert_equal("Example message #{idx * 2}", msg.text)
        assert((timestamps_before[idx] < msg.timestamp) \
               && (timestamps_after[idx] > msg.timestamp))
        msg = test_class.queue.pop
        assert_instance_of(Rutema::RunnerMessage, msg)
        assert_equal(:not_started, msg.status)
        assert_equal('Example Test', msg.test)
        assert_equal("Example message #{idx * 2 + 1}", msg.text)
        assert((timestamps_before[idx] < msg.timestamp) \
               && (timestamps_after[idx] > msg.timestamp))
      end
    end

    def test_message_something
      # Create a class to use for testing
      test_class = TestClass.new

      # Verify that the queue is empty
      assert(test_class.queue.empty?)

      # Try to insert a message of an unrecognized type
      test_class.message(5)

      # Verify that the queue is still empty
      assert(test_class.queue.empty?)
    end

    def test_message_string
      # Create a class to use for testing
      test_class = TestClass.new

      # Verify that the queue is empty
      assert(test_class.queue.empty?)

      # Insert a few Message instances into the queue
      timestamps_after = []
      timestamps_before = []
      (0..44).step(1).each do |idx|
        timestamps_before[idx] = Time.now
        test_class.message("Example message #{idx}")
        timestamps_after[idx] = Time.now
      end

      # Verify the queue and its contents
      assert_equal(45, test_class.queue.size)
      (0..44).step(1).each do |idx|
        msg = test_class.queue.pop
        assert_instance_of(Rutema::Message, msg)
        assert_equal('', msg.test)
        assert_equal("Example message #{idx}", msg.text)
        assert((timestamps_before[idx] < msg.timestamp) \
               && (timestamps_after[idx] > msg.timestamp))
      end
    end
  end
end
