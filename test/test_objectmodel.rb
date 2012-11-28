$:.unshift File.join(File.dirname(__FILE__),"..","lib")
require 'test/unit'
require 'rutema/objectmodel'
module TestRutema
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
      assert(/step - .*DummyCommand.*/=~step.name)
      assert_equal("output", step.output)
      assert_equal("error", step.error)
      assert_equal(:not_executed, step.status)
      assert_nothing_raised() { step.run }
      assert_equal(:success, step.status)
      assert_nothing_raised() { step.reset }
      assert_equal(:not_executed, step.status)
      assert_equal("", step.output)
      assert(/0 - step - .*DummyCommand.*- not_executed/=~step.to_s)
    end
  end
  class TestSpecification<Test::Unit::TestCase
    def test_new
      spec=Rutema::TestSpecification.new(:name=>"name",:title=>"title",:description=>"description")
      assert_equal("name", spec.name)
      assert_equal("title", spec.title)
      assert_equal("description", spec.description)
      assert_not_nil(spec.scenario)
      assert(spec.requirements.empty?)
      assert_equal("name - title", spec.to_s)
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