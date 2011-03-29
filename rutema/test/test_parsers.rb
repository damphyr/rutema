$:.unshift File.join(File.dirname(__FILE__),'..','lib')
require 'test/unit'
require 'ostruct'

require 'rubygems'
require 'patir/command'
require 'mocha'

require 'rutema/parsers/base'
require 'rutema/parsers/xml'

#$DEBUG=true
module TestRutema
  class TestSpecificationParser<Test::Unit::TestCase
    def test_specification_parser
      parser=nil
      assert_nothing_raised() { parser=Rutema::SpecificationParser.new({}) }
      assert_not_nil(parser)
      assert(!parser.configuration.empty?)
      assert_raise(Rutema::ParserError) { parser.parse_specification("foo") }
    end
  end
  class TestBaseXMlParser<Test::Unit::TestCase
    SAMPLE_SPEC=<<-EOT
    <specification name="sample">
    <title>Title</title>
    <description>Description</description>
    <scenario>
    <step/>
    <another_step script="script"/>
    </scenario>
    </specification>
    EOT
    INCLUDE_SPEC=<<-EOT
    <specification name="include">
    <title>Title</title>
    <description>Description</description>
    <scenario>
    <step/>
    <include_scenario file="#{File.expand_path(File.dirname(__FILE__))}/distro_test/specs/include.scenario"/>
    </scenario>
    </specification>
    EOT
    BAD_INCLUDE_SPEC=<<-EOT
    <specification name="bad_include">
    <title>Title</title>
    <description>Description</description>
    <scenario>
    <include_scenario file=unknown.scenario"/>
    </scenario>
    </specification>
    EOT
    MISSING_INCLUDE_SPEC=<<-EOT
    <specification name="bad_include">
    <title>Title</title>
    <description>Description</description>
    <scenario>
    <include_scenario/>
    </scenario>
    </specification>
    EOT

    def test_parse_specification
      parser=Rutema::BaseXMLParser.new({})
      specification=parser.parse_specification(SAMPLE_SPEC)
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
      parser=Rutema::BaseXMLParser.new({})
      specification=parser.parse_specification(INCLUDE_SPEC)
      assert_equal(3, specification.scenario.steps.size)
      assert(specification.scenario.steps[2].has_included_in?)
      assert_raise(Rutema::ParserError) {  parser.parse_specification(BAD_INCLUDE_SPEC) }
      assert_raise(Rutema::ParserError) {  parser.parse_specification(MISSING_INCLUDE_SPEC) }
    end

  end
  class TestExtensibleXMlParser<Test::Unit::TestCase
    SAMPLE_SPEC=<<-EOT
    <specification name="sample">
    <title>Title</title>
    <description>Description</description>
    <scenario>
    <step/>
    <another_step script="script"/>
    </scenario>
    </specification>
    EOT
    def test_parse_specification
      parser=Rutema::ExtensibleXMLParser.new({})
      assert_not_nil(parser.configuration)
      specification=nil
      assert_nothing_raised() { specification=parser.parse_specification(SAMPLE_SPEC) }
      assert_equal(2, specification.scenario.steps.size)
    end
    def test_parse_error
      parser=Rutema::ExtensibleXMLParser.new({})
      assert_not_nil(parser.configuration)
      specification=nil
      assert_raise(Rutema::ParserError) { specification=parser.parse_specification("<") }
    end
  end
  class TestMinimalXMlParser<Test::Unit::TestCase
    SAMPLE_SPEC=<<-EOT
    <specification name="sample">
    <title>Title</title>
    <description>Description</description>
    <scenario>
    <echo/>
    <command cmd="l"/>
    </scenario>
    </specification>
    EOT
    def test_parse_specification
      parser=Rutema::MinimalXMLParser.new({})
      specification=nil
      assert_nothing_raised() { specification=parser.parse_specification(SAMPLE_SPEC) }
      assert_not_nil(specification)
      assert_equal(2, specification.scenario.steps.size)
      assert_equal("Description", specification.description)
      assert_equal("Title", specification.title)
      assert_equal("sample", specification.name)
    end
  end
end