require 'minitest'
require_relative '../lib/rutema/reporters/junit'
require 'mocha/setup'

module TestRutema
  class TestReporters<Minitest::Test
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
