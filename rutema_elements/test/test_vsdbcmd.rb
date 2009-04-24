$:.unshift File.join(File.dirname(__FILE__),"..","lib")
require 'test/unit'
require 'rutema/elements/win32'
require 'rubygems'
require 'patir/base'
require 'mocha'

class TestSqlcmd <Test::Unit::TestCase
  include Rutema::Elements::SQLServer
  def test_missing_configuration
    cmd_conf=mock()
    cmd_conf.expects(:vsdbcmd).returns(nil)
    @configuration=mock()
    @configuration.expects(:tools).returns(cmd_conf)
    step=mock()
    assert_raise(Rutema::ParserError) { element_vsdbcmd(step)  }
  end
  def test_empty_configuration
    cmd_conf=mock()
    cmd_conf.expects(:vsdbcmd).returns({}).times(2)
    @configuration=mock()
    @configuration.expects(:tools).returns(cmd_conf).times(2)
    step=mock()
    assert_raise(Rutema::ParserError) { element_vsdbcmd(step)  }
  end
  def test_normal_flow
    @logger=Patir.setup_logger
    cfg={:configuration=>{:path=>File.join(File.dirname(__FILE__),"data/sample.dbschema"),:cs=>"connection"}}
    cmd_conf=mock()
    cmd_conf.expects(:vsdbcmd).returns(cfg).times(3)
    @configuration=mock()
    @configuration.expects(:tools).returns(cmd_conf).times(3)
    step=mock_simple_step
    assert_nothing_raised() { element_vsdbcmd(step)  }
  end
  private
  def mock_simple_step
    step=mock()
    step.expects(:has_script_root?).returns(false)
    step.expects(:has_dbschema?).returns(true)
    step.expects(:dbschema).returns(File.join(File.dirname(__FILE__),"data","sample.dbschema"))
    step.expects(:has_manifest?).returns(true)
    step.expects(:manifest).returns(File.join(File.dirname(__FILE__),"data","sample.dbschema"))
    step.expects(:has_overrides?).returns(false)
    step.expects(:has_connection_string?).returns(false)
    step.expects(:cmd=)
    return step
  end
end