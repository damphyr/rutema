# Copyright (c) 2007-2020 Vassilis Rizopoulos. All rights reserved.
require 'ostruct'
require 'test/unit'
require 'mocha/test_unit'

require_relative '../lib/rutema/core/errors'
require_relative '../lib/rutema/parsers/xml'


#$DEBUG=true
module TestRutema
  module Samples
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
    <include_scenario file="#{File.expand_path(File.dirname(__FILE__))}/data/include.scenario"/>
    </scenario>
    </specification>
    EOT
    BAD_INCLUDE_SPEC=<<-EOT
    <specification name="bad_include">
    <title>Title</title>
    <description>Description</description>
    <scenario>
    <include_scenario file="unknown.scenario"/>
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
    MINIMAL_SPEC=<<-EOT
    <specification name="sample">
    <title>Title</title>
    <description>Description</description>
    <scenario>
    <echo/>
    <command cmd="l"/>
    </scenario>
    </specification>
    EOT
    INCLUDE_SCENARIO=<<-EOT
    <?xml version="1.0" encoding="UTF-8"?>
    <scenario>
      <echo>This is a step from an included scenario</echo>
      <echo>And another step from the included scenario</echo>
    </scenario>
    EOT
  end

  ##
  # Test Rutema::Parsers::SpecificationParser
  class TestSpecificationParser < Test::Unit::TestCase
    def test_specification_parser
      parser = nil
      assert_nothing_raised { parser = Rutema::Parsers::SpecificationParser.new({}) }
      assert_not_nil(parser)
      assert(parser.configuration.empty?, 'Configuration is not empty')
      assert_raise(Rutema::ParserError) { parser.parse_specification('foo') }
      assert_raise(Rutema::ParserError) { parser.parse_setup('foo') }
      assert_raise(Rutema::ParserError) { parser.parse_teardown('foo') }
      assert_nothing_raised { parser.validate_configuration }
    end
  end
end
