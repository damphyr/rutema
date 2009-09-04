$:.unshift File.join(File.dirname(__FILE__),"..","lib")

require 'test/unit'
require 'rubygems'
require 'rutema/gems'
#$DEBUG=true
module TestRutema
  require 'rutema/system'
  
  class TestRutemaXConfigurator<Test::Unit::TestCase
    def setup
      @prev_dir=Dir.pwd
      Dir.chdir(File.dirname(__FILE__))
    end
    def teardown
      Dir.chdir(@prev_dir)
    end
    def test_rutemax_configuration
      cfg=nil
      #load the valid configuration
      assert_nothing_raised() { cfg=Rutema::RutemaXConfigurator.new("distro_test/config/full.rutema").configuration}
      assert_not_nil(cfg.parser)
      assert_not_nil(cfg.reporters)
      assert_equal(1, cfg.reporters.size)
      assert_not_nil(cfg.tools)
      assert_not_nil(cfg.tools.test[:configuration])
      assert_not_nil(cfg.tools.test[:path])
      assert_equal("test", cfg.tools.test[:name])
      assert_not_nil(cfg.paths)
      assert_not_nil(cfg.paths.test)
      assert_not_nil(cfg.setup)
      assert_not_nil(cfg.teardown)
      assert_not_nil(cfg.check)
      assert_not_nil(cfg.tests)
      assert_not_nil(cfg.context)
    end
    
    def test_specification_paths
      cfg=Rutema::RutemaXConfigurator.new("distro_test/config/full.rutema").configuration
      assert_not_nil(cfg.tests)
    end
  end
end