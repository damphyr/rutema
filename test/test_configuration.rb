# Copyright (c) 2007-2020 Vassilis Rizopoulos. All rights reserved.

# frozen_string_literal: true

require_relative '../lib/rutema/core/configuration'
# $DEBUG=true
require 'test/unit'
require 'mocha/test_unit'

FULL_CONFIG =<<-EOT
  configure do |cfg|
    cfg.check = 'check.spec'
    cfg.context = { key: 'value' }
    cfg.parser = { class: Rutema::Parsers::SpecificationParser }
    cfg.path = { name: 'doc', path: '/usr/share/doc' }
    cfg.path = { name: 'src', path: '/usr/src' }
    cfg.reporter = { class: Rutema::Reporters::BlockReporter }
    cfg.tests = ['T001.spec']
    cfg.setup = 'setup.spec'
    cfg.teardown = 'teardown.spec'
    cfg.tool = { name: 'cat', path: '/usr/bin/cat', configuration: {} }
    cfg.tool = { name: 'echo', path: '/usr/bin/echo', configuration: { param: '-n' } }
  end
  EOT

IDENTIFIERS =<<-EOT
  configure do |cfg|
    cfg.parser={:class=>Rutema::Parsers::SpecificationParser}
    cfg.tests=[
      "../examples/specs/T001.spec",
      "22345",
      "../examples/specs/T003.spec",
    ]
  end
  EOT

module TestRutema
  class TestRutemaConfiguration < Test::Unit::TestCase
    def test_rutema_configuration
      cfg = 'foo.cfg'
      File.expects(:read).with('full.rutema').returns(FULL_CONFIG)
      File.expects(:exist?).with(File.expand_path('check.spec')).returns(true)
      File.expects(:exist?).with(File.expand_path('teardown.spec')).returns(true)
      File.expects(:exist?).with(File.expand_path('setup.spec')).returns(true)
      File.expects(:exist?).with('T001.spec').returns(false)
      # load the valid configuration
      assert_nothing_raised { cfg = Rutema::Configuration.new('full.rutema') }
      assert_not_nil(cfg.parser)
      assert_not_nil(cfg.reporters)
      assert_equal(1, cfg.reporters.size)
      assert_not_nil(cfg.tests)
      assert_not_nil(cfg.context)
      assert_instance_of(OpenStruct, cfg.paths)
      assert_equal('/usr/share/doc', cfg.paths.doc)
      assert_equal('/usr/src', cfg.paths.src)
      assert_instance_of(OpenStruct, cfg.tools)
      assert_equal({ name: 'cat', path: '/usr/bin/cat', configuration: {} },
                   cfg.tools.cat)
      assert_equal({ name: 'echo', path: '/usr/bin/echo', configuration: { param: '-n' } },
                   cfg.tools.echo)
    end

    def test_specification_paths
      File.expects(:read).with('test_identifiers.rutema').returns(IDENTIFIERS)
      cfg = Rutema::Configuration.new('test_identifiers.rutema')
      assert_not_nil(cfg.tests)
      assert_equal(3, cfg.tests.size)
      assert(cfg.tests.include?('22345'))
    end
  end
end
