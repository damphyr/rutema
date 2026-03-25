#  Copyright (c) 2021 Vassilis Rizopoulos. All rights reserved.

require "test/unit"
require "ostruct"
require "mocha/test_unit"
require_relative "../lib/rutema/core/engine"
require_relative "../lib/rutema/core/objectmodel"
require_relative "../lib/rutema/parsers/xml"

module TestRutema
  class MockRunner
    attr_accessor :setup, :teardown

    def initialize(config)
    end

    def run(_name, _scenario)
      return
    end
  end

  class MockReporter < Rutema::Reporters::EventReporter
    def run!
      @@updates = 0
      super
    end

    # rubocop:disable Lint/UnusedMethodArgument
    def update(data)
      # p data
      @@updates += 1
    end
    # rubocop:enable Lint/UnusedMethodArgument

    def exit
      super
    end

    def self.updates
      return @@updates
    end
  end

  class TestEngine < Test::Unit::TestCase
    def test_checks
      conf = {}
      assert_raise(NoMethodError) { Rutema::Engine.new(conf) }
      conf = OpenStruct.new(:parser => {}, :runner => {})
      assert_raise(Rutema::RutemaError) { Rutema::Engine.new(conf) }
    end

    def test_run
      conf = OpenStruct.new(:parser => { :class => Rutema::Parsers::XML },
                            :reporters => { MockReporter => { :class => MockReporter } },
                            :tools => {},
                            :paths => {},
                            :tests => ["#{__dir__}/data/sample.spec"],
                            :context => {})
      engine = Rutema::Engine.new(conf)
      engine.run
      assert_equal(8, MockReporter.updates)

      conf[:tests] = ["#{__dir__}/data/sample.spec", "#{__dir__}/data/duplicate_name.spec"]
      assert_raise(Rutema::ParserError) do
        engine = Rutema::Engine.new(conf)
        engine.run
      end
      sleep(0.1)
      assert_equal(2, MockReporter.updates)

      conf[:tests] = []
      assert_raise(Rutema::RutemaError) do
        engine = Rutema::Engine.new(conf)
        engine.run
      end

      conf[:tests] = ["#{__dir__}/data/sample.spec"]
      conf[:setup] = "#{__dir__}/data/setup.spec"
      engine = Rutema::Engine.new(conf)
      engine.run("#{__dir__}/data/sample.spec")
    end
  end
end
