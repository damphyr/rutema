# Copyright (c) 2007-2020 Vassilis Rizopoulos. All rights reserved.

# frozen_string_literal: true

require 'ostruct'
require 'test/unit'
require 'mocha/test_unit'
require 'patir/command'

require_relative '../lib/rutema/core/objectmodel'
require_relative '../lib/rutema/core/runner'

module TestRutema
  ##
  # Test Rutema::Runners::Default
  class TestRunner < Test::Unit::TestCase
    def test_new
      scenario = Rutema::Scenario.new([Rutema::Step.new('desc')])
      spec = Rutema::Specification.new(scenario: scenario)
      queue = Queue.new
      runner = Rutema::Runners::Default.new({}, queue)
      state = nil
      assert_nothing_raised { state = runner.run(spec) }
      assert_equal(1, state['steps'].size)
      assert_equal(6, queue.size)
      assert_equal('started', queue.pop.text)
      4.times { queue.pop }
      assert_equal('finished', queue.pop.text)
    end

    def test_run_exceptions
      step = Rutema::Step.new('bad', Patir::RubyCommand.new('bad') { raise 'Bad command' })
      scenario = Rutema::Scenario.new([step])
      spec = Rutema::Specification.new(scenario: scenario)
      queue = Queue.new
      runner = Rutema::Runners::Default.new({}, queue)
      state = nil
      assert_nothing_raised { state = runner.run(spec) }
      assert_equal(:error, state['status'])
    end
  end
end
