$:.unshift File.join(File.dirname(__FILE__),"..","lib")
require 'test/unit'

module TestRutema
  require 'rutema/specification'
  class DummyCommand
    include Patir::Command
    def initialize
      @name="dummy"
      @output="output"
      @error="error"
    end
  end
  class Dummy
    include Rutema::SpecificationElement
  end
  class TestStep<Test::Unit::TestCase
    def test_new
      step=Rutema::TestStep.new("test step",DummyCommand.new())
      assert(!step.attended?, "attended?")
      assert_not_equal("dummy", step.name)
      assert_equal("step", step.name)
      assert_equal("output", step.output)
      assert_equal("error", step.error)
      assert_equal(:not_executed, step.status)
      assert_nothing_raised() { step.run }
      assert_equal(:success, step.status)
      assert_nothing_raised() { step.reset }
      assert_equal(:not_executed, step.status)
      assert_equal("", step.output)
    end
  end
  class TestSpecification<Test::Unit::TestCase
    def test_new
      spec=Rutema::TestSpecification.new
      assert_equal("", spec.name)
      assert_equal("", spec.title)
      assert_equal("", spec.description)
      assert_not_nil(spec.scenario)
      assert(spec.requirements.empty?)
    end
  end
  class TestScenario<Test::Unit::TestCase
    def test_new
      scenario=Rutema::TestScenario.new
      assert(scenario.steps.empty?)
      assert(!scenario.attended?)
    end
    def test_add_step
      step=Rutema::TestStep.new("test step",DummyCommand.new())
      scenario=Rutema::TestScenario.new
      scenario.add_step(step)
      assert_equal(1,scenario.steps.size)
    end
  end
  class TestSpecificationElement<Test::Unit::TestCase
    def test_attribute
      obj=Dummy.new
      assert_raise(NoMethodError) { obj.name }
      obj.attribute(:name,"name")
      assert(obj.has_name?)
      assert_equal(obj.name, "name")
      assert_raise(NoMethodError) { obj.bool }
      obj.attribute(:bool,true)
      assert(obj.bool?)
      assert_equal(true, obj.bool)
      assert_raise(NoMethodError) { obj.text_bool }
      obj.attribute(:text_bool,"true")
      assert(obj.text_bool?)
      assert_not_equal(true, obj.text_bool)
    end
    
    def test_method_missing
      obj=Dummy.new
      assert_raise(NoMethodError) { obj.name }
      obj.name="name"
      assert(obj.has_name?)
      assert_equal(obj.name, "name")
    end
  end
end