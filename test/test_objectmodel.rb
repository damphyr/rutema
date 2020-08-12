# Copyright (c) 2007-2020 Vassilis Rizopoulos. All rights reserved.
require 'test/unit'
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
  class TestStep<Test::Unit::TestCase
    def test_new
      step=Rutema::Step.new("Step",DummyCommand.new())
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
      assert(/0 - .*DummyCommand.*/=~step.to_s)
    end
  end
  class TestScenario<Test::Unit::TestCase
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
  class TestSpecification<Test::Unit::TestCase
    def test_new
      spec=Rutema::Specification.new(:name=>"name",:title=>"title",:description=>"description")
      assert(!spec.has_version?, "Version present")
      assert_equal("name", spec.name)
      assert_equal("title", spec.title)
      assert_equal("description", spec.description)
      assert(!spec.has_scenario?,"Scenario present")
      spec.scenario="Foo"
      assert_not_nil(spec.scenario)
      assert_equal("name - title", spec.to_s)
      #we can arbitrarily add attributes to a spec
      spec.requirements=["R1","R2"]
      assert(spec.has_requirements?)
      assert_equal(2, spec.requirements.size)
    end
  end
end