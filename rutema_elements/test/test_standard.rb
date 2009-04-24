$:.unshift File.join(File.dirname(__FILE__),"..","lib")
require 'test/unit'
require 'rutema/elements/general'
require 'rubygems'
require 'mocha'

class TestStandard <Test::Unit::TestCase
  include Rutema::Elements::Standard
  def test_fail
    step=OpenStruct.new
    step.expects(:has_text?).returns(false)
    assert_nothing_raised(){ element_fail(step) }
    c=step.cmd
    assert_not_nil(c)
    assert_nothing_raised() { c.run }
    assert(!c.success?, "Command did not fail.")
    assert_equal("\nFail! ",c.error)
  end
  
  def test_fail_with_text
    step=OpenStruct.new
    step.expects(:has_text?).returns(true)
    step.expects(:text).returns("Text")
    assert_nothing_raised(){ element_fail(step) }
    c=step.cmd
    assert_not_nil(c)
    assert_nothing_raised() { c.run }
    assert(!c.success?, "Command did not fail.")
    assert_equal("\nFail! Text",c.error)
  end
  
  def test_wait
    step=OpenStruct.new
    step.expects(:has_timeout?).returns(true)
    step.expects(:timeout).returns(2)
    assert_nothing_raised(){ element_wait(step) }
    c=step.cmd
    assert_not_nil(c)
    t1=Time.now
    assert_nothing_raised() { c.run }
    assert(c.exec_time>=2)
  end
  def test_wait_no_timeout
    step=mock()
    step.expects(:has_timeout?).returns(false)
    assert_raise(Rutema::ParserError){ element_wait(step) }
  end
end