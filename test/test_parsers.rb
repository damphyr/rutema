#  Copyright (c) 2021 Vassilis Rizopoulos. All rights reserved.

require "test/unit"
require "ostruct"
require "mocha/test_unit"
require_relative "../lib/rutema/parsers/xml"

# $DEBUG=true
module TestRutema
  module Samples
    # rubocop:disable Style/MutableConstant
    SAMPLE_SPEC = <<-SCNR
    <specification name="sample">
    <title>Title</title>
    <description>Description</description>
    <scenario>
    <step/>
    <another_step script="script"/>
    </scenario>
    </specification>
    SCNR
    INCLUDE_SPEC = <<-SCNR
    <specification name="include">
    <title>Title</title>
    <description>Description</description>
    <scenario>
    <step/>
    <include_scenario file="#{__dir__}/data/include.scenario"/>
    </scenario>
    </specification>
    SCNR
    BAD_INCLUDE_SPEC = <<-SCNR
    <specification name="bad_include">
    <title>Title</title>
    <description>Description</description>
    <scenario>
    <include_scenario file="unknown.scenario"/>
    </scenario>
    </specification>
    SCNR
    MISSING_INCLUDE_SPEC = <<-SCNR
    <specification name="bad_include">
    <title>Title</title>
    <description>Description</description>
    <scenario>
    <include_scenario/>
    </scenario>
    </specification>
    SCNR
    MINIMAL_SPEC = <<-SCNR
    <specification name="sample">
    <title>Title</title>
    <description>Description</description>
    <scenario>
    <echo/>
    <command cmd="l"/>
    </scenario>
    </specification>
    SCNR
    INCLUDE_SCENARIO = <<-SCNR
    <?xml version="1.0" encoding="UTF-8"?>
    <scenario>
      <echo>This is a step from an included scenario</echo>
      <echo>And another step from the included scenario</echo>
    </scenario>
    SCNR
    # rubocop:enable Style/MutableConstant
  end

  class TestSpecificationParser < Test::Unit::TestCase
    def test_specification_parser
      parser = nil
      assert_nothing_raised { parser = Rutema::Parsers::SpecificationParser.new({}) }
      assert_not_nil(parser)
      assert(parser.configuration.empty?, "Configuration is not empty")
      assert_raise(Rutema::ParserError) { parser.parse_specification("foo") }
    end
  end

  class TestXMLParser < Test::Unit::TestCase
    def test_parse_specification # rubocop:disable Metrics/AbcSize
      config = stub
      config.stubs(:parser).returns({})
      parser = Rutema::Parsers::XML.new(config)
      specification = parser.parse_specification(Samples::SAMPLE_SPEC)
      assert_equal("sample", specification.name)
      assert_equal("Description", specification.description)
      assert_equal("Title", specification.title)
      assert(specification.scenario)
      assert_equal(2, specification.scenario.steps.size)
      assert_equal(1, specification.scenario.steps[0].number)
      assert_equal("another_step", specification.scenario.steps[1].step_type)
      assert_equal("script", specification.scenario.steps[1].script)
      assert_equal(2, specification.scenario.steps[1].number)
      assert_raise(Rutema::ParserError) { parser.parse_specification("") }
      assert_raise(Rutema::ParserError) { parser.parse_specification("missing.spec") }
    end

    def test_include
      config = stub
      config.stubs(:parser).returns({})
      parser = Rutema::Parsers::XML.new(config)
      specification = parser.parse_specification(Samples::INCLUDE_SPEC)
      assert_equal(3, specification.scenario.steps.size)
      assert(specification.scenario.steps[2].has_included_in?)
      assert_raise(Rutema::ParserError) {  parser.parse_specification(Samples::BAD_INCLUDE_SPEC) }
      assert_raise(Rutema::ParserError) {  parser.parse_specification(Samples::MISSING_INCLUDE_SPEC) }
    end

    def test_parse_error
      config = stub
      config.stubs(:parser).returns({})
      parser = Rutema::Parsers::XML.new(config)
      assert_not_nil(parser.configuration)
      assert_raise(Rutema::ParserError) { parser.parse_specification("<") }
    end
  end
end
