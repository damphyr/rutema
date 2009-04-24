require 'test/unit'
require 'ostruct'
require 'rutemaweb/ramaze_controller'
require 'rubygems'
require 'mocha'

class TestModel <Test::Unit::TestCase
  ActiveRecord::Base.establish_connection(:adapter  => "sqlite3",:database =>":memory:")
  Rutema::Model::Schema.up
  def setup
    @stp=Rutema::Model::Scenario.new
    @stp.name="test_setup"
    @trd=Rutema::Model::Scenario.new
    @trd.name="test_teardown"
    @tst=Rutema::Model::Scenario.new
    @tst.name="test"
    @r=Rutema::Model::Run.new
    @r.scenarios=[@stp,@tst,@trd]
  end
  def test_status
    assert_equal(:success,@r.status)
    t1=Rutema::Model::Scenario.new
    t1.name="failed"
    t1.stubs(:status).returns("error")
    @r.scenarios<<t1
    assert_equal(:error,@r.status)
  end
  def test_is_test?
    assert(!@stp.is_test?, "Setup as test")
    assert(!@trd.is_test?, "Teardown as test")
    assert(@tst.is_test?, "Test not a test")
  end
  def test_number_of_tests
    assert_equal(1, @r.number_of_tests)
  end
  def test_number_of_failed
    t1=Rutema::Model::Scenario.new
    t1.name="failed"
    t1.stubs(:status).returns("error")
    t2=Rutema::Model::Scenario.new
    t2.name="not executed"
    t2.stubs(:status).returns("not_executed")
    @tst.stubs(:status).returns("success")
    @r.scenarios<<t1
    @r.scenarios<<t2
    assert_equal(2,@r.number_of_failed)
  end
end