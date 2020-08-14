# Copyright (c) 2007-2020 Vassilis Rizopoulos. All rights reserved.

require 'test/unit'
require 'mocha/test_unit'

require_relative '../lib/rutema/core/engine'
require_relative '../lib/rutema/reporters/junit'

module TestRutema
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
      
      states={"_setup_"=>Rutema::ReportState.new(
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
      states={"_setup_"=>Rutema::ReportState.new(
          Rutema::RunnerMessage.new({"timestamp"=>Time.now, "duration"=>0.000157, "status"=>:success, "steps"=>[]})
        )
      }
      assert_equal(0,reporter.report([],states,[]))

      states={"_setup_"=>Rutema::ReportState.new(
          Rutema::RunnerMessage.new({"timestamp"=>Time.now, "duration"=>0.000157, "status"=>:error, "steps"=>[]})
        )
      }
      assert_equal(1,reporter.report([],states,[]))
    end
  end
end
