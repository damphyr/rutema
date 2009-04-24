$:.unshift File.join(File.dirname(__FILE__),"..","lib")
require 'test/unit'
require 'patir/base.rb'

class TestBase<Test::Unit::TestCase
  def teardown
    #clean up 
    File.delete("temp.log") if File.exists?("temp.log")
  end
  #simple match test
  def test_drb_service
    assert_equal("druby://service.host:7000",Patir.drb_service("service.host",7000))
  end
  #This is not actually testing anything meaningfull but can be expanded when we learn more about 
  #the logger
  def test_setup_logger
    logger=Patir.setup_logger
    assert_not_nil(logger)
    logger=Patir.setup_logger(nil,:silent)
    assert_not_nil(logger)
    logger=Patir.setup_logger("temp.log",:silent)
    assert_not_nil(logger)
    logger.close
  end
  
end