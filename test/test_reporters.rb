# Copyright (c) 2007-2020 Vassilis Rizopoulos. All rights reserved.

require 'test/unit'
require 'mocha/test_unit'

require_relative '../lib/rutema/core/engine'
require_relative '../lib/rutema/core/framework'
require_relative '../lib/rutema/reporters/junit'

module TestRutema
  class ConsoleTestMockConfiguration
    attr_reader :reporters

    def initialize(simulated_mode)
      @reporters = {}
      @reporters[Rutema::Reporters::Console] = { 'mode' => simulated_mode }
    end
  end

  ##
  # Test Rutema::Reporters::BlockReporter
  class TestBlockReporter < Test::Unit::TestCase
    def test_initialize
      assert_nothing_raised do
        Rutema::Reporters::BlockReporter.new(nil, nil)
      end
    end

    def test_report
      block_reporter = Rutema::Reporters::BlockReporter.new(nil, nil)
      assert_nothing_raised { block_reporter.report(nil, nil, nil) }
    end
  end

  ##
  # Test Rutema::Reporters::Console
  class TestConsole < Test::Unit::TestCase
    def test_initialize
      configurator = ConsoleTestMockConfiguration.new('normal')
      dispatcher = mock
      dispatcher.expects(:subscribe).once.returns(Queue.new).with \
        { |value| value.is_a?(Integer) }
      assert_nothing_raised do
        Rutema::Reporters::Console.new(configurator, dispatcher)
      end
    end

    def test_update_normal
      configurator = ConsoleTestMockConfiguration.new('normal')
      dispatcher = mock
      dispatcher.expects(:subscribe).once.returns(Queue.new).with \
        { |value| value.is_a?(Integer) }
      reporter = Rutema::Reporters::Console.new(configurator, dispatcher)
      output = capture_output do
        reporter.update(Rutema::Message.new(test: 'Test1', text: 'Test1 text'))
        reporter.update(Rutema::ErrorMessage.new(test: 'Test2', text: 'Test2 text'))
        reporter.update(Rutema::RunnerMessage.new(test: 'Test3', text: 'Test3 text'))
        reporter.update(Rutema::RunnerMessage.new('status' => :error, test: 'Test4', text: 'Test4 text'))
      end
      puts output
      assert_equal(["ERROR - Test2 Test2 text\nFATAL|Test4:Test4 text.\n", ''], output)
    end

    def test_update_off
      configurator = ConsoleTestMockConfiguration.new('off')
      dispatcher = mock
      dispatcher.expects(:subscribe).once.returns(Queue.new).with \
        { |value| value.is_a?(Integer) }
      reporter = Rutema::Reporters::Console.new(configurator, dispatcher)
      output = capture_output do
        reporter.update(Rutema::Message.new(test: 'Test1', text: 'Test1 text'))
        reporter.update(Rutema::ErrorMessage.new(test: 'Test2', text: 'Test2 text'))
        reporter.update(Rutema::RunnerMessage.new(test: 'Test3', text: 'Test3 text'))
      end
      assert_equal(['', ''], output)
    end

    def test_update_verbose
      configurator = ConsoleTestMockConfiguration.new('verbose')
      dispatcher = mock
      dispatcher.expects(:subscribe).once.returns(Queue.new).with \
        { |value| value.is_a?(Integer) }
      reporter = Rutema::Reporters::Console.new(configurator, dispatcher)
      output = capture_output do
        reporter.update(Rutema::Message.new(test: 'Test1', text: 'Test1 text'))
        reporter.update(Rutema::ErrorMessage.new(test: 'Test2',
                                                 text: 'Test2 text'))
        reporter.update(Rutema::RunnerMessage.new(test: 'Test3',
                                                  text: 'Test3 text'))
        reporter.update(Rutema::RunnerMessage.new('status' => :error,
                                                  test: 'Test4',
                                                  text: 'Test4 text'))
        reporter.update(Rutema::RunnerMessage.new('status' => :started,
                                                  test: 'Test5', text:
                                                  'Test5 text'))
      end
      puts output
      assert_equal(["Test1 Test1 text\n" \
                    "ERROR - Test2 Test2 text\n" \
                    "FATAL|Test4:Test4 text.\n" \
                    "Test5:Test5 text.\n", ''], output)
    end
  end

  ##
  # Test Rutema::Reporters::EventReporter
  class TestEventReporter < Test::Unit::TestCase
    def test_initialize
      dispatcher = mock
      dispatcher.expects(:subscribe).once.returns(Queue.new).with \
        { |value| value.is_a?(Integer) }
      assert_nothing_raised do
        Rutema::Reporters::EventReporter.new(nil, dispatcher)
      end
    end

    def test_threading
      dispatcher = mock
      test_queue = Queue.new
      (1..50).step(1) { |i| test_queue << i }
      dispatcher.expects(:subscribe).once.returns(test_queue).with \
        { |value| value.is_a?(Integer) }
      reporter = Rutema::Reporters::EventReporter.new(nil, dispatcher)
      reporter.run!
      timepoint_before = Time.now
      reporter.exit
      timepoint_after = Time.now
      expired_time = timepoint_after - timepoint_before
      assert(expired_time < 0.5)
    end

    def test_update
      dispatcher = mock
      dispatcher.expects(:subscribe).once.returns(Queue.new).with \
        { |value| value.is_a?(Integer) }
      reporter = Rutema::Reporters::EventReporter.new(nil, dispatcher)
      assert_nothing_raised { reporter.update(nil) }
    end
  end

  class TestReporters<Test::Unit::TestCase
    def test_junit
      #Rutema::Utilities.expects(:write_file).returns("OK")
      configuration = mock()
      configuration.expects(:reporters).returns(configuration)
      configuration.expects(:fetch).returns({:class=>Rutema::Reporters::JUnit,"filename"=>"rutema.junit.xml"})
      configuration.stubs(:context).returns({})
      dispatcher=mock()
      junit_reporter=Rutema::Reporters::JUnit.new(configuration,dispatcher)
      assert_equal("<?xml version='1.0'?><testsuite errors='0' failures='0' tests='0' time='0'/>", junit_reporter.process_data([],{},[]))
      
      states={"_setup_"=>Rutema::ReportTestState.new(
          Rutema::RunnerMessage.new({"timestamp"=>Time.now, "duration"=>0.000157, "status"=>:success, "steps"=>[]})
        )
      }

      assert_equal("<?xml version='1.0'?><testsuite errors='0' failures='0' tests='0' time='0.000157'><testcase name='_setup_' time='0.000157'/></testsuite>", junit_reporter.process_data([],states,[]))
    end

    def test_summary
      #Rutema::Utilities.expects(:write_file).returns("OK")
      configuration = mock()
      configuration.expects(:reporters).returns(configuration)
      configuration.expects(:fetch).returns({:class=>Rutema::Reporters::JUnit,"filename"=>"rutema.junit.xml"})
      configuration.stubs(:context).returns({})
      dispatcher=mock()  

      reporter=Rutema::Reporters::Summary.new(configuration,dispatcher)
      assert_equal(0,reporter.report([],{},[]))
      states={"_setup_"=>Rutema::ReportTestState.new(
          Rutema::RunnerMessage.new({"timestamp"=>Time.now, "duration"=>0.000157, "status"=>:success, "steps"=>[]})
        )
      }
      assert_equal(0,reporter.report([],states,[]))

      states={"_setup_"=>Rutema::ReportTestState.new(
          Rutema::RunnerMessage.new({"timestamp"=>Time.now, "duration"=>0.000157, "status"=>:error, "steps"=>[]})
        )
      }
      assert_equal(1,reporter.report([],states,[]))
    end
  end
end
