require 'minitest'
require 'ostruct'
require 'mocha/setup'
require_relative '../lib/rutema/core/engine'
require_relative '../lib/rutema/core/objectmodel'
require_relative '../lib/rutema/parsers/xml'

module TestRutema
  class MockRunner
    attr_accessor :setup,:teardown
    def initialize config
      
    end

    def run name,scenario
      return 
    end
  end

  class MockReporter < Rutema::Reporters::EventReporter
    def run!
      @@updates=0
      super
    end
    def update data
      #p data
      @@updates+=1
    end
    def exit
      super
    end
    def self.updates
      return @@updates
    end
  end

  class TestEngine<Minitest::Test
    def test_checks
      conf={}
      assert_raises(NoMethodError){Rutema::Engine.new(conf)}
      conf=OpenStruct.new(:parser=>{},:runner=>{})
      assert_raises(Rutema::RutemaError){Rutema::Engine.new(conf)}
    end

    def test_run
      conf=OpenStruct.new(:parser=>{:class=>Rutema::Parsers::XML},
          :reporters=>{MockReporter=>{:class=>MockReporter}},
          :tools=>{},
          :paths=>{},
          :tests=>["#{File.expand_path(File.dirname(__FILE__))}/data/sample.spec",
            "#{File.expand_path(File.dirname(__FILE__))}/data/duplicate_name.spec"],
          :context=>{})
      engine=nil
      engine=Rutema::Engine.new(conf)
      engine.run
      assert_equal(5, MockReporter.updates)
      #test for a spec that is not in the config and re-entry
      assert_raises(Rutema::RutemaError) { engine.run("foo")}
      assert_equal(1, MockReporter.updates)
    end
  end
end