$:.unshift File.join(File.dirname(__FILE__),"..")
require 'test/unit'
require 'ostruct'

require 'rubygems'
require 'patir/command'
require 'mocha'

require 'lib/rutema/objectmodel'
require 'lib/rutema/runners/default'
require 'lib/rutema/runners/step'

#$DEBUG=true
module TestRutema
  class TestRunner<Test::Unit::TestCase
    def test_new
      runner=Rutema::Runner.new
      assert(!runner.attended?)
      assert_nil(runner.setup)
      assert_nil(runner.teardown)
      assert(runner.states.empty?)
    end
    def test_run
      runner=Rutema::Runner.new
      scenario=Rutema::TestScenario.new
      state1=runner.run("test1",scenario)
      state2=runner.run("test2",scenario)
      assert_equal(state1, runner["test1"])
      assert_equal(state2, runner["test2"])
      assert_equal(2, runner.states.size)
      state2=runner.run("test2",scenario)
      assert_equal(2, runner.states.size)
    end
    def test_run_exceptions
      runner=Rutema::Runner.new
      scenario=Rutema::TestScenario.new
      step=Rutema::TestStep.new("bad",Patir::RubyCommand.new("bad"){|cmd| raise "Bad command"})
      scenario.add_step(step)
      state1=:success
      assert_nothing_raised() { state1=runner.run("test1",scenario) }
      assert_equal(:error, state1.status)
    end
    def test_reset
      runner=Rutema::Runner.new
      scenario=Rutema::TestScenario.new
      state1=runner.run("test1",scenario)
      state2=runner.run("test2",scenario)
      assert_equal(2, runner.states.size)
      runner.reset
      assert(runner.states.empty?)
    end
    def test_ignore
      step=OpenStruct.new("status"=>:not_executed)
      step.stubs(:number).returns(1)
      step.stubs(:name).returns("mock")
      step.stubs(:step_type).returns("mock")
      step.stubs(:output).returns("mock")
      step.stubs(:error).returns("")
      step.stubs(:strategy).returns(:attended)
      step.stubs(:exec_time).returns(12)
      step.stubs(:has_cmd?).returns(false)
      step.expects(:ignore?).returns(true)
      step.expects(:status).times(6).returns(:not_executed).then.returns(:not_executed).then.returns(:error).then.returns(:warning).then.returns(:warning).then.returns(:warning)
      scenario=Rutema::TestScenario.new
      scenario.expects(:attended?).returns(false)
      scenario.stubs(:steps).returns([step])
      runner=Rutema::Runner.new
      runner.run("ignore",scenario)
      assert(runner.success?,"run is not a success")
    end
  end
end