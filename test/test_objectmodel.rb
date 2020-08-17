# Copyright (c) 2007-2020 Vassilis Rizopoulos. All rights reserved.
require 'test/unit'
require_relative '../lib/rutema/core/objectmodel'

module TestRutema
  class DummyCommand
    include Patir::Command
    def initialize
      @error = 'error'
      @name = 'dummy'
      @output = 'output'
    end
  end

  class Dummy
    include Rutema::SpecificationElement
  end

  ##
  # Test Rutema::SpecificationElement
  class TestSpecificationElement < Test::Unit::TestCase
    def test_attribute
      obj = Dummy.new

      # Atribute with a String value
      assert_raise(NoMethodError) { obj.name }
      assert_raise(NoMethodError) { obj.name? }
      obj.attribute(:name, 'name')
      assert(obj.has_name?)
      assert(obj.name?)
      assert_equal(obj.name, 'name')
      obj.name = 'Another name'
      assert_equal('Another name', obj.name)

      # Attribute with a boolean value
      assert_raise(NoMethodError) { obj.bool }
      assert_raise(NoMethodError) { obj.bool? }
      obj.attribute(:bool, true)
      assert(obj.has_bool?)
      assert(obj.bool?)
      assert_equal(true, obj.bool)
      obj.bool = false
      assert_equal(false, obj.bool)

      # Attribute with a textual representation of a boolean value
      assert_raise(NoMethodError) { obj.text_bool }
      assert_raise(NoMethodError) { obj.text_bool? }
      obj.attribute(:text_bool, 'true')
      assert(obj.has_text_bool?)
      assert(obj.text_bool?)
      assert_equal('true', obj.text_bool)
      obj.text_bool = 'false'
      assert_equal('false', obj.text_bool)
    end

    def test_method_missing
      obj = Dummy.new
      assert_raise(NoMethodError) { obj.name }
      obj.name = 'Some name'
      assert(obj.has_name?)
      assert(obj.name?)
      assert_equal(obj.name, 'Some name')
    end

    def test_respond_to
      obj = Dummy.new
      [false, true].each do |include_all|
        assert_false(obj.respond_to?(:has_a_name, include_all))
        assert_false(obj.respond_to?(:a_name, include_all))
        assert_false(obj.respond_to?(:a_name=, include_all))
        assert_false(obj.respond_to?(:a_name?, include_all))
      end

      obj.attribute(:a_name, 'Some name')

      [false, true].each do |include_all|
        assert(obj.respond_to?(:has_a_name, include_all))
        assert(obj.respond_to?(:a_name, include_all))
        assert(obj.respond_to?(:a_name=, include_all))
        assert(obj.respond_to?(:a_name?, include_all))
      end
    end
  end

  ##
  # Test Rutema::Step
  class TestStep < Test::Unit::TestCase
    def test_default_initialize
      step = Rutema::Step.new
      assert_raise(NoMethodError) { step.cmd }
      assert_equal('no command associated', step.error)
      assert_equal(0, step.exec_time)
      assert_equal(false, step.ignore)
      assert_equal(false, step.ignore?)
      assert_equal('step', step.name)
      assert_equal('step', step.name_with_parameters)
      step.reset
      assert_equal('', step.output)
      # ToDo(markuspg): Fix symbols
      # assert_equal(:not_executed, step.run)
      # assert_equal(:not_executed, step.run({}))
      assert_equal(:warning, step.status)
      step.status = :test_status
      assert_equal(:warning, step.status)
      assert_equal('step', step.step_type)
      assert_equal('', step.text)
      assert_equal('0 - step', step.to_s)
    end

    def test_initialize
      dummy_cmd = DummyCommand.new
      step = Rutema::Step.new('Test Step', dummy_cmd)
      
      assert_equal(dummy_cmd, step.cmd)
      assert_equal('error', step.error)
      assert_equal(0, step.exec_time)
      assert_equal(false, step.ignore)
      assert_equal(false, step.ignore?)
      assert(/step - #<TestRutema::DummyCommand:/ =~ step.name)
      assert(/step - #<TestRutema::DummyCommand:/ =~ step.name_with_parameters)
      step.reset
      assert_equal('', step.output)
      # ToDo(markuspg): Fix symbols
      # assert_equal(:not_executed, step.run)
      # assert_equal(:not_executed, step.run({}))
      # assert_equal(not_executed, step.status)
      step.status = :test_status
      assert_equal(:test_status, step.status)
      assert_equal('step', step.step_type)
      assert_equal('Test Step', step.text)
      assert(/0 - #<TestRutema::DummyCommand:/ =~ step.to_s)
    end
  end

  ##
  # Test Rutema::Scenario
  class TestScenario < Test::Unit::TestCase
    def test_adding_a_step
      scenario = Rutema::Scenario.new([])
      assert(scenario.steps.empty?)
      step = Rutema::Step.new('Step', DummyCommand.new)
      scenario = Rutema::Scenario.new([step])
      assert_equal(1, scenario.steps.size)
      scenario.add_step(step)
      assert_equal(2, scenario.steps.size)
    end

    def test_initialize
      scenario = Rutema::Scenario.new([])
      assert_instance_of(Array, scenario.steps)
      assert(scenario.steps.empty?)

      scenario = Rutema::Scenario.new([1, 2, 3])
      assert_instance_of(Array, scenario.steps)
      assert_false(scenario.steps.empty?)
      assert_equal(3, scenario.steps.size)
    end

    def test_overwriting_steps
      scenario = Rutema::Scenario.new([1, 2, 3])
      assert_instance_of(Array, scenario.steps)
      assert_false(scenario.steps.empty?)
      assert_equal(3, scenario.steps.size)

      scenario.steps = 'Generally this does not belong here'

      assert_instance_of(String, scenario.steps)
      assert_false(scenario.steps.empty?)
      assert_equal(35, scenario.steps.size)
    end
  end

  ##
  # Test Rutema::Specification
  class TestSpecification < Test::Unit::TestCase
    def test_default_initialization
      spec = Rutema::Specification.new({})
      assert_equal('', spec.description)
      assert_equal('', spec.filename)
      assert_equal('', spec.name)
      assert_equal('', spec.title)
      assert_false(spec.has_version?,
                   ':version present in default initialized Specification')
      assert_equal(' - ', spec.to_s)
    end

    def test_full_initialization
      test_scenario = Rutema::Scenario.new([])
      spec = Rutema::Specification.new(description: 'Some example specification',
                                       filename: 'example.spec',
                                       name: 'example_spec',
                                       scenario: test_scenario,
                                       title: 'Example Spec',
                                       version: '0.9.8')
      assert_equal('Some example specification', spec.description)
      assert_equal('example.spec', spec.filename)
      assert_equal('example_spec', spec.name)
      # ToDo(markuspg): Bug?
      # assert_equal(test_scenario, spec.scenario)
      assert_equal('Example Spec', spec.title)
      assert_equal('0.9.8', spec.version)
      spec.scenario = 'Foo'
      assert_equal('Foo', spec.scenario)

      # Check stringification
      assert_equal('example_spec - Example Spec', spec.to_s)

      # Check if arbitrary value can be added
      spec.requirements = %w[R1 R2]
      assert(spec.has_requirements?)
      assert_equal(2, spec.requirements.size)
    end
  end
end
