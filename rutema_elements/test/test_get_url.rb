$:.unshift File.join(File.dirname(__FILE__),"..","lib")
require 'test/unit'
require 'rutema/elements/general'
require 'rubygems'
require 'mocha'

class TestGetUrl <Test::Unit::TestCase
  include Rutema::Elements::Web
  def test_missing_configuration
    @configuration=mock()
    @configuration.expects(:get_url).returns(nil)
    @configuration.expects(:tools).returns(@configuration)
    step = mock()
    step.expects(:has_address?).returns(false)
    assert_raise(Rutema::ParserError) { element_get_url(step)  }
  end
  def test_empty_configuration
    @configuration=mock()
    @configuration.expects(:get_url).returns({}).times(2)
    @configuration.expects(:tools).returns(@configuration).times(2)
    step = mock()
    step.expects(:has_address?).returns(false)
    assert_raise(Rutema::ParserError) { element_get_url(step)  }
  end
  
  def test_empty_configuration_with_address
    @configuration=mock()
    @configuration.expects(:get_url).returns({}).times(2)
    @configuration.expects(:tools).returns(@configuration).times(2)
    step = mock_simple_step
    step.expects(:address).returns("http://localhost:9137")
    step.expects(:has_retry?).returns(false).times(2)
   assert_nothing_raised(){ element_get_url(step)  }
  end
  
  def test_retry_checking
    mock_configuration
    step=mock_simple_step
    step.expects(:address).returns("http://localhost")
    step.expects(:has_pause?).returns(false)
    step.expects(:has_retry?).returns(true).times(2)
    step.expects(:retry).returns(3)
    assert_nothing_raised(){ element_get_url(step) }
  end
  
  def test_pause_checking
    mock_configuration
    step=mock_simple_step
    step.expects(:address).returns("http://localhost")
    step.expects(:has_pause?).returns(true)
    step.expects(:has_retry?).returns(true).times(2)
    step.expects(:retry).returns(3)
    step.expects(:pause).returns(3)
    assert_nothing_raised(){ element_get_url(step) }
  end
  #tests against an unlikely port on localhost to make sure retries work correctly
  def test_running_with_retry
    mock_configuration
    step=OpenStruct.new
    step.expects(:has_address?).returns(true)
    step.expects(:address).returns("http://localhost:9137").times(2)
    step.expects(:has_pause?).returns(true)
    step.expects(:has_retry?).returns(true).times(2)
    step.expects(:retry).returns(3)
    step.expects(:pause).returns(3)
    assert_nothing_raised(){ element_get_url(step) }
    c=step.cmd
    assert_nothing_raised() { c.run }
    assert(!c.success?, "Should not be succesfull.")
    p c.output
  end
  
  #run it against google to check it with a working site
  def test_known_server
    mock_configuration
    step=OpenStruct.new
    step.expects(:has_address?).returns(true)
    step.expects(:address).returns("http://www.google.com").times(2)
    step.expects(:has_pause?).returns(true)
    step.expects(:has_retry?).returns(true).times(2)
    step.expects(:retry).returns(3)
    step.expects(:pause).returns(3)
    element_get_url(step)
    c=step.cmd
    assert_nothing_raised() { c.run }
    assert(c.success?, "Should be succesfull.")
    p c.output
  end
  private
  def mock_configuration
    @configuration=mock()
    @configuration.expects(:get_url).returns({:address=>"http://localhost"}).times(2)
    @configuration.expects(:tools).returns(@configuration).times(2)
  end
  def mock_simple_step
    step=mock()
    step.expects(:has_address?).returns(true)
    step.expects(:address).returns("http://localhost")
    step.expects(:cmd=)
    return step
  end
end