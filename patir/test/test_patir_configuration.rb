$:.unshift File.join(File.dirname(__FILE__),"..","lib")
require 'test/unit'

require 'patir/configuration'
module Patir
  class TestConfigurator<Test::Unit::TestCase
    def setup
      @prev_dir=Dir.pwd
      Dir.chdir(File.dirname(__FILE__))
    end
    def teardown
      Dir.chdir(@prev_dir)
    end
    def test_configuration
      c=Patir::Configurator.new("samples/empty.cfg")
      assert_equal(c.configuration,c)
    end
  end
end