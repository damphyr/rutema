# Copyright (c) 2007-2020 Vassilis Rizopoulos. All rights reserved.

# frozen_string_literal: true

require_relative '../lib/rutema/core/configuration'
# $DEBUG=true
require 'test/unit'
require 'mocha/test_unit'

BASE_CONFIG_EXTENSION =<<-EOT
  configure do |cfg|
    cfg.reporter = { class: Rutema::Reporters::BlockReporter }
    cfg.runner = { class: Rutema::Runners::Default }
  end
  EOT

FULL_CONFIG =<<-EOT
  configure do |cfg|
    cfg.check = 'check.spec'
    cfg.context = { key_a: 'A value' }
    cfg.context = { key_b: 'Another value' }
    cfg.context = { key_a: 'Oops', key_c: 'One more value' }
    cfg.parser = { class: Rutema::Parsers::SpecificationParser }
    cfg.path = { name: 'doc', path: '/usr/share/doc' }
    cfg.path = { name: 'src', path: '/usr/src' }
    cfg.reporter = { class: Rutema::Reporters::BlockReporter }
    cfg.reporter = { class: Rutema::Reporters::EventReporter }
    cfg.runner = { class: Rutema::Runners::Default }
    cfg.setup = 'setup.spec'
    cfg.suite_setup = 'suite_setup.spec'
    cfg.suite_teardown = 'suite_teardown.spec'
    cfg.teardown = 'teardown.spec'
    cfg.tests = ['T001.spec', 'T002.spec', 'T003.spec', 'T004.spec']
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

class InitTestClass
  include Rutema::ConfigurationDirectives

  def initialize
    init
  end
end

module TestRutema
  ##
  # Test Rutema::ConfigurationDirectives
  class TestConfigurationDirectives < Test::Unit::TestCase
    def test_init
      test_instance = InitTestClass.new
      assert_instance_of(Hash, test_instance.context)
      assert_instance_of(OpenStruct, test_instance.paths)
      assert_instance_of(Hash, test_instance.reporters)
      assert_instance_of(Array, test_instance.tests)
      assert_instance_of(OpenStruct, test_instance.tools)
    end

    def test_context
      test_instance = InitTestClass.new
      assert_raise(Rutema::ConfigurationException) do
        test_instance.context = 5
      end
      test_instance.context = { a: 1, b: 2, c: 3 }
      test_instance.context = { a: 4, c: 5, d: 6 }
      assert_equal({ a: 4, b: 2, c: 5, d: 6 }, test_instance.context)
    end

    def test_parser
      test_instance = InitTestClass.new
      assert_raise(Rutema::ConfigurationException) do
        test_instance.parser = { something: 'else' }
      end
      assert_raise(Rutema::ConfigurationException) do
        test_instance.parser = { class: Rutema::Configuration }
      end
      test_instance.parser = { class: Rutema::Parsers::SpecificationParser }
      test_instance.parser = { class: Rutema::Parsers::XML, 'strict_mode': true }
      assert_equal({ class: Rutema::Parsers::XML, 'strict_mode': true },
                   test_instance.parser)
    end

    def test_path
      test_instance = InitTestClass.new
      assert_raise(Rutema::ConfigurationException) do
        test_instance.path = { path: '/usr/src' }
      end
      assert_raise(Rutema::ConfigurationException) do
        test_instance.path = { name: 'sources' }
      end
      test_instance.path = { name: 'binaries', path: '/usr/bin' }
      test_instance.path = { name: 'home', path: '/home', something_else: 5 }
      test_instance.path = { name: 'binaries', path: '/usr/local/bin' }
      assert_equal('/usr/local/bin', test_instance.paths.binaries)
      assert_equal('/home', test_instance.paths.home)
    end

    def test_reporter
      test_instance = InitTestClass.new
      assert_raise(Rutema::ConfigurationException) do
        test_instance.reporter = { klass: Rutema::Reporters::Console }
      end
      test_instance.reporter = { class: Rutema::Reporters::BlockReporter, opt: 6 }
      test_instance.reporter = { class: Rutema::Reporters::Collector, attr: 5 }
      test_instance.reporter = { class: Rutema::Reporters::BlockReporter }
      assert_equal({ Rutema::Reporters::BlockReporter \
                     => { class: Rutema::Reporters::BlockReporter }, \
                     Rutema::Reporters::Collector \
                     => { class: Rutema::Reporters::Collector, attr: 5 } }, \
                   test_instance.reporters)
    end

    def test_runner
      test_instance = InitTestClass.new
      assert_raise(Rutema::ConfigurationException) do
        test_instance.runner = { klass: Rutema::Runners::Default }
      end
      test_instance.runner = { class: Rutema::Runners::NoOp, opt: 6 }
      test_instance.runner = { class: Rutema::Runners::Default }
      test_instance.runner = { class: Rutema::Runners::NoOp, attr: 8 }
      assert_equal({ class: Rutema::Runners::NoOp, attr: 8 }, \
                   test_instance.runner)
    end

    def test_setup
      test_instance = InitTestClass.new
      assert_raise(Rutema::ConfigurationException) do
        test_instance.setup = 'setup.spec'
      end
      test_instance.setup = 'test/data/sample.spec'
      test_instance.setup = 'test/data/setup.spec'
      assert_equal(File.expand_path('test/data/setup.spec'),
                   test_instance.setup)
    end

    def test_suite_setup
      test_instance = InitTestClass.new
      assert_raise(Rutema::ConfigurationException) do
        test_instance.suite_setup = 'setup.spec'
      end
      test_instance.suite_setup = 'test/data/sample.spec'
      test_instance.suite_setup = 'test/data/setup.spec'
      assert_equal(File.expand_path('test/data/setup.spec'),
                   test_instance.suite_setup)
      test_instance.check = 'test/data/sample.spec'
      assert_equal(File.expand_path('test/data/sample.spec'),
                   test_instance.check)
    end

    def test_suite_teardown
      test_instance = InitTestClass.new
      assert_raise(Rutema::ConfigurationException) do
        test_instance.suite_teardown = 'setup.spec'
      end
      test_instance.suite_teardown = 'test/data/sample.spec'
      test_instance.suite_teardown = 'test/data/setup.spec'
      assert_equal(File.expand_path('test/data/setup.spec'),
                   test_instance.suite_teardown)
    end

    def test_teardown
      test_instance = InitTestClass.new
      assert_raise(Rutema::ConfigurationException) do
        test_instance.teardown = 'setup.spec'
      end
      test_instance.teardown = 'test/data/sample.spec'
      test_instance.teardown = 'test/data/setup.spec'
      assert_equal(File.expand_path('test/data/setup.spec'),
                   test_instance.teardown)
    end

    def test_tests
      test_instance = InitTestClass.new
      test_instance.tests = ['5', 'test/data/sample.spec', 'nil', 'setup.spec']
      test_instance.tests = ['nil', '6', 'test/data/setup.spec']
      assert_equal(['5', File.expand_path('test/data/sample.spec'), 'nil', \
                    'setup.spec', 'nil', '6', \
                    File.expand_path('test/data/setup.spec')],
                   test_instance.tests)
    end

    def test_tools
      test_instance = InitTestClass.new
      assert_raise(Rutema::ConfigurationException) do
        test_instance.tool = { path: '/usr/bin/firefox' }
      end
      test_instance.tool = { name: 'firefox', path: '/usr/bin/firefox',
                             url: 'https://www.example.org' }
      test_instance.tool = { name: 'inkscape', path: '/usr/local/bin/inkscape',
                             file: 'rutema.svg' }
      test_instance.tool = { name: 'firefox', path: '/usr/bin/firefox' }
      assert_equal({ name: 'firefox', path: '/usr/bin/firefox' },
                   test_instance.tools.firefox)
      assert_equal({ name: 'inkscape', path: '/usr/local/bin/inkscape',
                     file: 'rutema.svg' },
                   test_instance.tools.inkscape)
    end
  end

  ##
  # Test Rutema::Configuration
  class TestRutemaConfiguration < Test::Unit::TestCase
    def test_rutema_configuration_configure
      File.expects(:read).with('test_identifiers.rutema').returns(IDENTIFIERS)
      cfg = Rutema::Configuration.new('test_identifiers.rutema')
      cfg.configure { |conf| conf.context = { key_a: 'A value' } }
      assert_equal({ key_a: 'A value' }, cfg.context)
    end

    def test_rutema_configuration_import
      File.expects(:exist?).with(File.expand_path('base_config.rutema')).returns(true)
      File.expects(:exist?).with('../examples/specs/T001.spec').returns(true)
      File.expects(:exist?).with('22345').returns(true)
      File.expects(:exist?).with('../examples/specs/T003.spec').returns(true)
      File.expects(:read).with(File.expand_path('base_config.rutema')).returns(BASE_CONFIG_EXTENSION)
      File.expects(:read).with('test_identifiers.rutema').returns(IDENTIFIERS)
      cfg = Rutema::Configuration.new('test_identifiers.rutema')
      cfg.import('base_config.rutema')
      assert_equal({ Rutema::Reporters::BlockReporter => \
                     { class: Rutema::Reporters::BlockReporter } }, cfg.reporters)
      assert_equal({ class: Rutema::Runners::Default }, cfg.runner)
    end

    def test_rutema_configuration_initialize
      cfg = 'foo.cfg'
      File.expects(:read).with('full.rutema').returns(FULL_CONFIG)
      File.expects(:exist?).with(File.expand_path('check.spec')).returns(true)
      File.expects(:exist?).with(File.expand_path('setup.spec')).returns(true)
      File.expects(:exist?).with(File.expand_path('suite_setup.spec')).returns(true)
      File.expects(:exist?).with(File.expand_path('suite_teardown.spec')).returns(true)
      File.expects(:exist?).with(File.expand_path('teardown.spec')).returns(true)
      File.expects(:exist?).with('T001.spec').returns(false)
      File.expects(:exist?).with('T002.spec').returns(true)
      File.expects(:exist?).with('T003.spec').returns(true)
      File.expects(:exist?).with('T004.spec').returns(true)
      # load the valid configuration
      assert_nothing_raised { cfg = Rutema::Configuration.new('full.rutema') }
      assert_equal('full.rutema', cfg.filename)
      assert_instance_of(Hash, cfg.context)
      assert_equal({ key_a: 'Oops', key_b: 'Another value',
                     key_c: 'One more value' }, cfg.context)
      assert_instance_of(Hash, cfg.parser)
      assert_equal(1, cfg.parser.size)
      assert_equal({ class: Rutema::Parsers::SpecificationParser }, cfg.parser)
      assert_instance_of(Hash, cfg.reporters)
      assert_equal(2, cfg.reporters.size)
      assert_equal({ Rutema::Reporters::BlockReporter \
                     => { class: Rutema::Reporters::BlockReporter }, \
                     Rutema::Reporters::EventReporter \
                     => { class: Rutema::Reporters::EventReporter } }, cfg.reporters)
      assert_instance_of(Hash, cfg.runner)
      assert_equal(1, cfg.runner.size)
      assert_equal({ class: Rutema::Runners::Default }, cfg.runner)
      assert_instance_of(Array, cfg.tests)
      puts cfg.tests
      assert_equal(['T001.spec',
                    File.expand_path('T002.spec'),
                    File.expand_path('T003.spec'),
                    File.expand_path('T004.spec')], cfg.tests)
      assert_instance_of(OpenStruct, cfg.paths)
      assert_equal('/usr/share/doc', cfg.paths.doc)
      assert_equal('/usr/src', cfg.paths.src)
      assert_equal(File.expand_path('setup.spec'), cfg.setup)
      assert_equal(File.expand_path('suite_setup.spec'), cfg.suite_setup)
      assert_equal(File.expand_path('suite_teardown.spec'), cfg.suite_teardown)
      assert_equal(File.expand_path('teardown.spec'), cfg.teardown)
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
