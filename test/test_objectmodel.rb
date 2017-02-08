require 'minitest'
require_relative '../lib/rutema/core/objectmodel'
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
  class TestSpecificationElement<Minitest::Test
    def test_attribute
      obj=Dummy.new
      assert_raises(NoMethodError) { obj.name }
      obj.attribute(:name,"name")
      assert(obj.has_name?)
      assert_equal(obj.name, "name")
      assert_raises(NoMethodError) { obj.bool }
      obj.attribute(:bool,true)
      assert(obj.bool?)
      assert_equal(true, obj.bool)
      assert_raises(NoMethodError) { obj.text_bool }
      obj.attribute(:text_bool,"true")
      assert(obj.text_bool?)
      refute_equal(true, obj.text_bool)
    end
    
    def test_method_missing
      obj=Dummy.new
      assert_raises(NoMethodError) { obj.name }
      obj.name="name"
      assert(obj.has_name?)
      assert_equal(obj.name, "name")
    end
  end
  class TestStep<Minitest::Test
    def test_new
      step=Rutema::Step.new("Step",DummyCommand.new())
      refute_equal("dummy", step.name)
      assert(/step - .*DummyCommand.*/=~step.name)
      assert_equal("output", step.output)
      assert_equal("error", step.error)
      assert_equal(:not_executed, step.status)
      refute_nil(step.run)
      assert_equal(:success, step.status)
      refute_nil(step.reset)
      assert_equal(:not_executed, step.status)
      assert_equal("", step.output)
      assert(/0 - .*DummyCommand.*/=~step.to_s)
    end
  end
  class TestScenario<Minitest::Test
    def test_add_step
      scenario=Rutema::Scenario.new([])
      assert(scenario.steps.empty?)
      step=Rutema::Step.new("Step",DummyCommand.new())
      scenario=Rutema::Scenario.new([step])
      assert_equal(1,scenario.steps.size)
      scenario.add_step(step)
      assert_equal(2,scenario.steps.size)
    end
  end
  class TestSpecification<Minitest::Test
    def test_new
      spec=Rutema::Specification.new(:name=>"name",:title=>"title",:description=>"description")
      assert(!spec.has_version?, "Version present")
      assert_equal("name", spec.name)
      assert_equal("title", spec.title)
      assert_equal("description", spec.description)
      assert(!spec.has_scenario?,"Scenario present")
      spec.scenario="Foo"
      refute_nil(spec.scenario)
      assert_equal("name - title", spec.to_s)
      #we can arbitrarily add attributes to a spec
      spec.requirements=["R1","R2"]
      assert(spec.has_requirements?)
      assert_equal(2, spec.requirements.size)
    end
  end
end