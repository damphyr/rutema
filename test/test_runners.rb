require 'test/unit'
require 'ostruct'
require 'patir/command'
require 'mocha/setup'

require_relative '../lib/rutema/core/objectmodel'
require_relative '../lib/rutema/core/runner'

module TestRutema
  class TestRunner<Test::Unit::TestCase
    def test_new
      scenario=Rutema::Scenario.new([Rutema::Step.new("desc")])
      spec=Rutema::Specification.new(:scenario=>scenario)
      queue=Queue.new
      runner=Rutema::Runners::Default.new({},queue)
      state=nil
      assert_nothing_raised() { state=runner.run(spec) }
      assert_equal(1, state["steps"].size)
      assert_equal(6, queue.size)
      assert_equal("started", queue.pop.text)
      4.times{queue.pop}
      assert_equal("finished", queue.pop.text)
    end
    
    def test_run_exceptions
      step=Rutema::Step.new("bad",Patir::RubyCommand.new("bad"){|cmd| raise "Bad command"})
      scenario=Rutema::Scenario.new([step])
      spec=Rutema::Specification.new(:scenario=>scenario)
      queue=Queue.new
      runner=Rutema::Runners::Default.new({},queue)
      state=nil
      assert_nothing_raised() { state=runner.run(spec) }
      assert_equal(:error, state['status'])
    end
  end
end