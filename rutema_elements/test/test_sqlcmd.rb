$:.unshift File.join(File.dirname(__FILE__),"..","lib")
require 'test/unit'
require 'rutema/elements/win32'
require 'rubygems'
require 'mocha'

class TestSqlcmd <Test::Unit::TestCase
  include Rutema::Elements::SQLServer
  def test_missing_configuration
    sqlcmd_conf=mock()
    sqlcmd_conf.expects(:sqlcmd).returns(nil)
    @configuration=mock()
    @configuration.expects(:tools).returns(sqlcmd_conf)
    step=mock_simple_step
    assert_nothing_raised() { element_sqlcmd(step)  }
  end
  def test_empty_configuration
    sqlcmd_conf=mock()
    sqlcmd_conf.expects(:sqlcmd).returns({}).times(2)
    @configuration=mock()
    @configuration.expects(:tools).returns(sqlcmd_conf).times(2)
    step=mock_simple_step
    assert_nothing_raised() { element_sqlcmd(step)  }
  end
  private
  def mock_simple_step
    step=mock()
    step.expects(:has_script?).returns(true)
    step.expects(:has_script_root?).returns(false)
    step.expects(:script).returns(File.join(File.dirname(__FILE__),"data","sample.sql"))
    step.expects(:has_database?).returns(false)
    step.expects(:has_host?).returns(false)
    step.expects(:has_server?).returns(false)
    step.expects(:has_password?).returns(false)
    step.expects(:has_username?).returns(false)
    step.expects(:has_level?).returns(false)
    step.expects(:cmd=)
    return step
  end
end