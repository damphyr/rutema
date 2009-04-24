#  Copyright (c) 2007 Vassilis Rizopoulos. All rights reserved.
$:.unshift File.join(File.dirname(__FILE__),"..","..","lib")
require 'rubygems'
require 'test/unit'
require 'rubot/overseer/configuration.rb'

module TestRubot
  
  class TestOverseerConfigurator<Test::Unit::TestCase
    def setup
      @prev_dir=Dir.pwd
      Dir.chdir(File.dirname(__FILE__))
    end
    def teardown
      Dir.chdir(@prev_dir)
    end
    def test_configuration
      cfg=nil
      #and a valid file should not raise anything
      assert_nothing_raised(){cfg=Rubot::Overseer::Configurator.new("samples/valid_overseer_config.cfg")}
      assert_not_nil(cfg.configuration)
      assert_equal("Sample",cfg.configuration.projects[0][:name])
      assert_equal("http://www.bogus.net",cfg.configuration.projects[0][:url])
    end
    
    def test_missing_file
      #missing file should raise an error
      assert_raise(Patir::ConfigurationException){Rubot::Overseer::Configurator.new("missing.cfg")}
    end
    
    def test_unknown
      #unknown directive should raise an error
      assert_raise(Patir::ConfigurationException){Rubot::Overseer::Configurator.new("samples/unknown.cfg")}
    end
  end
end