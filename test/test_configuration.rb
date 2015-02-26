
require_relative '../lib/rutema/core/configuration'
#$DEBUG=true
require 'test/unit'
require 'mocha/setup'

FULL_CONFIG=<<-EOT
configuration.parser={:class=>Rutema::Parsers::SpecificationParser}
configuration.reporter={:class=>Rutema::Reporters::BlockReporter}
configuration.tests=["T001.spec"]
configuration.tool={:name=>"test",:path=>".",:configuration=>{:key=>"value"}}
configuration.path={:name=>"test",:path=>"."}
configuration.context={:key=>"value"}
configuration.check="check.spec"
configuration.teardown="teardown.spec"
configuration.setup="setup.spec" 
EOT

IDENTIFIERS=<<-EOT
configuration.parser={:class=>Rutema::Parsers::SpecificationParser}
configuration.tests=[
"../examples/specs/T001.spec",
"22345",
"../examples/specs/T003.spec",
]
EOT

module TestRutema
  class TestRutemaConfigurator<Test::Unit::TestCase
    def test_rutema_configuration
      cfg="foo.cfg"
      File.expects(:read).with("full.rutema").returns(FULL_CONFIG)
      File.expects(:exists?).with(File.expand_path("check.spec")).returns(true)
      File.expects(:exists?).with(File.expand_path("teardown.spec")).returns(true)
      File.expects(:exists?).with(File.expand_path("setup.spec")).returns(true)
      File.expects(:exists?).with("T001.spec").returns(false)
      #load the valid configuration
      assert_nothing_raised() { cfg=Rutema::RutemaConfigurator.new("full.rutema").configuration}
      assert_not_nil(cfg.parser)
      assert_not_nil(cfg.reporters)
      assert_equal(1, cfg.reporters.size)
      assert_not_nil(cfg.tools)
      assert_not_nil(cfg.tools.test[:configuration])
      assert_not_nil(cfg.tools.test[:path])
      assert_equal("test", cfg.tools.test[:name])
      assert_not_nil(cfg.paths)
      assert_not_nil(cfg.paths.test)
      assert_not_nil(cfg.setup)
      assert_not_nil(cfg.teardown)
      assert_not_nil(cfg.check)
      assert_not_nil(cfg.tests)
      assert_not_nil(cfg.context)
    end
    
    def test_specification_paths
      File.expects(:read).with("test_identifiers.rutema").returns(IDENTIFIERS)
      cfg=Rutema::RutemaConfigurator.new("test_identifiers.rutema").configuration
      assert_not_nil(cfg.tests)
      assert_equal(3, cfg.tests.size)
      assert(cfg.tests.include?('22345'))
    end
  end
end