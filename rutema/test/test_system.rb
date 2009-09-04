$:.unshift File.join(File.dirname(__FILE__),"..","lib")
require 'rubygems'
require 'test/unit'
require 'ostruct'
require 'patir/command'
require 'mocha'

#$DEBUG=true
module TestRutema
  require 'rutema/system'
  class TestBaseXMlParser<Test::Unit::TestCase
    SAMPLE_SPEC=<<-EOT
    <specification name="sample">
    <title>Title</title>
    <description>Description</description>
    <scenario>
    <step/>
    <another_step script="script"/>
    </scenario>
    </specification>
    EOT
    INCLUDE_SPEC=<<-EOT
    <specification name="include">
    <title>Title</title>
    <description>Description</description>
    <scenario>
    <step/>
    <include_scenario file="#{File.expand_path(File.dirname(__FILE__))}/distro_test/specs/include.scenario"/>
    </scenario>
    </specification>
    EOT
    BAD_INCLUDE_SPEC=<<-EOT
    <specification name="bad_include">
    <title>Title</title>
    <description>Description</description>
    <scenario>
    <include_scenario file=unknown.scenario"/>
    </scenario>
    </specification>
    EOT
    MISSING_INCLUDE_SPEC=<<-EOT
    <specification name="bad_include">
    <title>Title</title>
    <description>Description</description>
    <scenario>
    <include_scenario/>
    </scenario>
    </specification>
    EOT

    def test_parse_specification
      parser=Rutema::BaseXMLParser.new({})
      specification=parser.parse_specification(SAMPLE_SPEC)
      assert_equal("sample",specification.name)
      assert_equal("Description", specification.description)
      assert_equal("Title", specification.title)
      assert(specification.scenario)
      assert_equal(2, specification.scenario.steps.size)
      assert_equal(1, specification.scenario.steps[0].number)
      assert_equal("another_step", specification.scenario.steps[1].step_type)
      assert_equal("script", specification.scenario.steps[1].script)
      assert_equal(2, specification.scenario.steps[1].number)
      assert_raise(Rutema::ParserError) { parser.parse_specification("") }
      assert_raise(Rutema::ParserError) { parser.parse_specification("missing.spec") }
    end

    def test_include
      parser=Rutema::BaseXMLParser.new({})
      specification=parser.parse_specification(INCLUDE_SPEC)
      assert_equal(3, specification.scenario.steps.size)
      assert(specification.scenario.steps[2].has_included_in?)
      assert_raise(Rutema::ParserError) {  parser.parse_specification(BAD_INCLUDE_SPEC) }
      assert_raise(Rutema::ParserError) {  parser.parse_specification(MISSING_INCLUDE_SPEC) }
    end

  end

  class TestExtensibleXMlParser<Test::Unit::TestCase
    SAMPLE_SPEC=<<-EOT
    <specification name="sample">
    <title>Title</title>
    <description>Description</description>
    <scenario>
    <step/>
    <another_step script="script"/>
    </scenario>
    </specification>
    EOT
    def test_parse_specification
      parser=Rutema::ExtensibleXMLParser.new({})
      assert_nil(parser.configuration)
      assert_nothing_raised() { specification=parser.parse_specification(SAMPLE_SPEC) }
    end
  end
  class TestMinimalXMlParser<Test::Unit::TestCase
    SAMPLE_SPEC=<<-EOT
    <specification name="sample">
    <title>Title</title>
    <description>Description</description>
    <scenario>
    <echo/>
    <command cmd="l"/>
    </scenario>
    </specification>
    EOT
    def test_parse_specification
      parser=Rutema::MinimalXMLParser.new({})
      assert_nothing_raised() { @specification=parser.parse_specification(SAMPLE_SPEC) }
      assert_equal(2, @specification.scenario.steps.size)
    end
  end
  class TestCoordinator<Test::Unit::TestCase
    def setup
      @prev_dir=Dir.pwd
      Dir.chdir(File.dirname(__FILE__))
    end
    def teardown
      Dir.chdir(@prev_dir)
    end
    def test_run
      conf=OpenStruct.new(:parser=>{:class=>Rutema::BaseXMLParser},
      :tools=>{},
      :paths=>{},
      :tests=>["distro_test/specs/sample.spec","distro_test/specs/duplicate_name.spec"],
      :reporters=>[],
      :context=>{})
      coord=nil
      assert_nothing_raised() do 
        coord=Rutema::Coordinator.new(conf)
        coord.run(:all)
        assert_equal(1,coord.parse_errors.size)
        coord=Rutema::Coordinator.new(conf)
        coord.run(:attended)
        assert_equal(1,coord.parse_errors.size)
        coord=Rutema::Coordinator.new(conf)
        coord.run(:unattended)
        assert_equal(1,coord.parse_errors.size)
        coord=Rutema::Coordinator.new(conf)
        coord.run("distro_test/specs/sample.spec")
        assert_equal(0,coord.parse_errors.size)
        coord=Rutema::Coordinator.new(conf)
        coord.run("distro_test/specs/no_title.spec")
        assert_equal(1,coord.parse_errors.size)
      end
      puts coord.to_s if $DEBUG
    end
  end

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
      step.expects(:status).times(5).returns(:not_executed).then.returns(:not_executed).then.returns(:error).then.returns(:warning).then.returns(:warning)
      scenario=Rutema::TestScenario.new
      scenario.expects(:attended?).returns(false)
      scenario.stubs(:steps).returns([step])
      runner=Rutema::Runner.new
      runner.run("ignore",scenario)
      assert(runner.success?,"run is not a success")
    end
  end

end