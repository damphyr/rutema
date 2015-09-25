require 'test/unit'
require_relative '../lib/rutema/reporters/junit'
require 'mocha/setup'

module TestRutema
  class TestReporters<Test::Unit::TestCase
    def test_junit
      #Rutema::Utilities.expects(:write_file).returns("OK")
      configuration = mock()
      configuration.expects(:reporters).returns(configuration)
      configuration.expects(:fetch).returns({:class=>Rutema::Reporters::JUnit,"filename"=>"rutema.junit.xml"})
      configuration.stubs(:context).returns({})
      dispatcher=mock()
      junit_reporter=Rutema::Reporters::JUnit.new(configuration,dispatcher)
      assert_equal("<?xml version='1.0'?><testsuite errors='0' failures='0' tests='0' time='0'/>", junit_reporter.process_data([],[],[]))
    end
  end
end
