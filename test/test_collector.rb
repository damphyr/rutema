# Copyright (c) 2007-2020 Vassilis Rizopoulos. All rights reserved.

# frozen_string_literal: true

require 'test/unit'
require 'mocha/test_unit'

require_relative '../lib/rutema/core/reporter'

class MockConfiguration
end

module TestRutema
  class TestCollector < Test::Unit::TestCase
    def test_initialize
      dispatcher = mock
      dispatcher.expects(:subscribe).once.returns(Queue.new).with \
        { |value| value.is_a?(Integer) }
      collector = assert_nothing_raised do
        Rutema::Reporters::Collector.new(MockConfiguration.new,
                                         dispatcher)
      end
      assert_instance_of(Array, collector.errors)
      assert_instance_of(Hash, collector.states)
    end

    def test_update
      dispatcher = mock
      dispatcher.expects(:subscribe).once.returns(Queue.new).with \
        { |value| value.is_a?(Integer) }
      collector = Rutema::Reporters::Collector.new(MockConfiguration.new,
                                                   dispatcher)
      collector.update(Rutema::ErrorMessage.new(test: 'Test1', text: 'Test1 text'))
      collector.update(Rutema::RunnerMessage.new(duration: 14, number: 1,
                                                 test: 'Test2', text: 'Test2 text'))
      collector.update(Rutema::RunnerMessage.new(duration: 32, number: 2,
                                                 test: 'Test2', text: 'Test2 text'))
      last_test_2_timestamp = Time.now
      collector.update(Rutema::RunnerMessage.new(duration: 5, number: 3,
                                                 test: 'Test2', text: 'Test2 text',
                                                 timestamp: last_test_2_timestamp))
      collector.update(Rutema::ErrorMessage.new(test: 'Test3', text: 'Test3 text'))
      collector.update(Rutema::ErrorMessage.new(test: 'Test4', text: 'Test4 text'))
      assert_equal(3, collector.errors.size)
      collector.update(Rutema::RunnerMessage.new(duration: 3, number: 1,
                                                 test: 'Test5', text: 'Test5 text'))
      last_test_5_timestamp = Time.now
      collector.update(Rutema::RunnerMessage.new(duration: 8, number: 2,
                                                 test: 'Test5', text: 'Test5 text',
                                                 timestamp: last_test_5_timestamp))
      assert_equal(3, collector.errors.size)
      assert_equal(2, collector.states.size)
      assert_equal('Test2', collector.states['Test2'].test)
      assert_equal(3, collector.states['Test2'].steps.size)
      # ToDo(markuspg): Fix invalid duration values
      # assert_equal(51, collector.states['Test2'].duration)
      assert_equal('Test5', collector.states['Test5'].test)
      assert_equal(2, collector.states['Test5'].steps.size)
      # assert_equal(11, collector.states['Test5'].duration)
    end
  end
end
