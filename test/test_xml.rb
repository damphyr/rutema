# Copyright (c) 2007-2020 Vassilis Rizopoulos. All rights reserved.

module TestRutema
  ##
  # Test Rutema::Parsers::XML
  class TestXMLParser<Test::Unit::TestCase
    def test_parse_specification
      config=stub()
      config.stubs(:parser).returns({})
      parser=Rutema::Parsers::XML.new(config)
      specification=parser.parse_specification(Samples::SAMPLE_SPEC)
      assert_equal("sample",specification.name)
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
      config=stub()
      config.stubs(:parser).returns({})
      parser=Rutema::Parsers::XML.new(config)
      specification=parser.parse_specification(Samples::INCLUDE_SPEC)
      assert_equal(3, specification.scenario.steps.size)
      assert(specification.scenario.steps[2].has_included_in?)
      assert_raise(Rutema::ParserError) {  parser.parse_specification(Samples::BAD_INCLUDE_SPEC) }
      assert_raise(Rutema::ParserError) {  parser.parse_specification(Samples::MISSING_INCLUDE_SPEC) }
    end
    def test_parse_error
      config=stub()
      config.stubs(:parser).returns({})
      parser=Rutema::Parsers::XML.new(config)
      assert_not_nil(parser.configuration)
      specification=nil
      assert_raise(Rutema::ParserError) { specification=parser.parse_specification("<") }
    end
  end
end
