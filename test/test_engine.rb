# Copyright (c) 2007-2020 Vassilis Rizopoulos. All rights reserved.
require 'ostruct'
require 'test/unit'
require 'mocha/test_unit'
require_relative '../lib/rutema/core/engine'
require_relative '../lib/rutema/core/objectmodel'
require_relative '../lib/rutema/parsers/xml'

module TestRutema
  class MockRunner
    attr_accessor :setup, :teardown

    def initialize(_config) end

    def run(_name, _scenario) end
  end

  class MockReporter < Rutema::Reporters::EventReporter
    def run!
      @@updates = 0
      super
    end

    def update(_data)
      # p data
      @@updates += 1
    end

    def exit
      super
    end

    def self.updates
      @@updates
    end
  end

  ##
  # Test Rutema::Engine
  class TestEngine < Test::Unit::TestCase
    def test_checks
      conf = {}
      assert_raise(NoMethodError) { Rutema::Engine.new(conf) }
      conf = OpenStruct.new(parser: {}, runner: {})
      assert_raise(Rutema::RutemaError) { Rutema::Engine.new(conf) }
    end

    def test_run
      conf = OpenStruct.new(parser: { class: Rutema::Parsers::XML },
                            reporters: { MockReporter => { class: MockReporter } },
                            tools: {},
                            paths: {},
                            tests: ["#{File.expand_path(File.dirname(__FILE__))}/data/sample.spec"],
                            context: {})
      engine = nil
      engine = Rutema::Engine.new(conf)
      engine.run
      assert_equal(8, MockReporter.updates)

      conf[:tests] = ["#{File.expand_path(File.dirname(__FILE__))}/data/sample.spec",
                      "#{File.expand_path(File.dirname(__FILE__))}/data/duplicate_name.spec"]
      assert_raise(Rutema::ParserError) do
        engine = Rutema::Engine.new(conf)
        engine.run
      end
      assert_equal(1, MockReporter.updates)

      conf[:tests] = []
      assert_raise(Rutema::RutemaError) do
        engine = Rutema::Engine.new(conf)
        engine.run
      end

      conf[:tests] = ["#{File.expand_path(File.dirname(__FILE__))}/data/sample.spec"]
      conf[:setup] = "#{File.expand_path(File.dirname(__FILE__))}/data/setup.spec"
      engine = Rutema::Engine.new(conf)
      engine.run("#{File.expand_path(File.dirname(__FILE__))}/data/sample.spec")
    end
  end
end
