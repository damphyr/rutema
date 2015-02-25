require 'test/unit'
require 'ostruct'
require 'mocha/setup'
require_relative '../lib/rutema/core/engine'
require_relative '../lib/rutema/reporters/base'
require_relative '../lib/rutema/core/objectmodel'

module TestRutema
  class MockParser
    def initialize config
      
    end

    def parse_specification data
      return Rutema::TestSpecification.new(:name=>data,:description=>data)
    end
  end

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
      @@updates+=1
      #p data
    end
    def exit
      super
    end
    def self.updates
      return @@updates
    end
  end

  class TestEngine<Test::Unit::TestCase
    def test_checks
      conf={}
      assert_raise(Rutema::RutemaError){Rutema::Engine.new(conf)}
      conf=OpenStruct.new(:parser=>{},:runner=>{})
      assert_raise(Rutema::RutemaError){Rutema::Engine.new(conf)}
    end

    def test_run
      conf=OpenStruct.new(:parser=>{:class=>TestRutema::MockParser},
          :runner=>{:class=>TestRutema::MockRunner},
          :tools=>{},
          :paths=>{},
          :tests=>["data/sample.spec","data/duplicate_name.spec"],
          :reporters=>[{:class=>MockReporter}],
          :context=>{})
      engine=nil
      assert_nothing_raised() do 
        engine=Rutema::Engine.new(conf)
        engine.run
      end
      assert_equal(5, MockReporter.updates)
      #test for a spec that is not in the config and re-entry
      engine.run("foo")
      assert_equal(5, MockReporter.updates)
    end
  end
end