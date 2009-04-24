$:.unshift File.join(File.dirname(__FILE__),"..","..","lib")
require 'test/unit'
require 'rubot/worker/configuration'

module TestRubot
  module TestWorker
    class TestConfigurator<Test::Unit::TestCase
      def setup
        @prev_dir=Dir.pwd
        Dir.chdir(File.dirname(__FILE__))
      end
      def teardown
        Dir.chdir(@prev_dir)
      end
      def test_missing_file
        #missing file should raise an error
        assert_raise(Patir::ConfigurationException){Rubot::Worker::Configurator.new("missing.cfg")}
      end
      def test_worker_configuration
        cfg=nil
        #and a valid file should not raise anything
        assert_nothing_raised(){cfg=Rubot::Worker::Configurator.new("samples/valid_worker_config.cfg")}
        assert_not_nil(cfg.configuration)
        assert_equal("127.0.0.1",cfg.configuration.endpoint[:ip])
        assert_equal("7000",cfg.configuration.endpoint[:port])
        assert_equal("127.0.0.1",cfg.configuration.overseer[:ip])
        assert_equal("7777",cfg.configuration.overseer[:port])
      end
      def test_unknown
        #unknown directive should raise an error
        assert_raise(Patir::ConfigurationException){Rubot::Worker::Configurator.new("samples/unknown.cfg")}
      end
    end
    class TestConfiguration<Test::Unit::TestCase
      class A
        include Rubot::Worker::Configuration
        attr_accessor :configuration
        def initialize
          @configuration=Hash.new
        end
      end
      def test_module
        testbed=A.new
        testbed.name="unit test"
        assert_equal("unit test",testbed.configuration[:name])
        #
        assert_nothing_raised(Patir::ConfigurationException) { testbed.overseer={:ip=>"127.0.0.1",:port=>8888}  }
        assert_equal({:ip=>"127.0.0.1",:port=>8888},testbed.configuration[:overseer])
        assert_raise(Patir::ConfigurationException) { testbed.overseer={:ip=>"127.0.0.1"} }
        assert_raise(Patir::ConfigurationException) { testbed.overseer={:port=>""} }
        assert_raise(Patir::ConfigurationException) { testbed.overseer={:crap=>"127.0.0.1"} }
        #
        assert_nothing_raised(Patir::ConfigurationException) { testbed.endpoint={:ip=>"127.0.0.1",:port=>8888}  }
        assert_equal({:ip=>"127.0.0.1",:port=>8888},testbed.configuration[:endpoint])
        assert_raise(Patir::ConfigurationException) { testbed.endpoint={:ip=>"127.0.0.1"} }
        assert_raise(Patir::ConfigurationException) { testbed.endpoint={:port=>""} }
        assert_raise(Patir::ConfigurationException) { testbed.endpoint={:crap=>"127.0.0.1"} }
      end
    end
  end
end