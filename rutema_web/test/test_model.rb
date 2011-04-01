$:.unshift File.join(File.dirname(__FILE__),"..")
require 'test/unit'
require 'ostruct'
require 'rubygems'
require 'mocha'
require 'lib/rutema_web/activerecord/model'

class TestModel <Test::Unit::TestCase
  ::ActiveRecord::Base.establish_connection(:adapter  => "sqlite3",:database =>":memory:")
  Rutema::ActiveRecord::Schema.up
  def setup
    @stp=Rutema::ActiveRecord::Scenario.new(:name=>"TC000_setup",:attended=>false,:status=>"success",:start_time=>Time.now)
    @stp.steps<<Rutema::ActiveRecord::Step.new(:name=>"echo",:number=>1,:status=>"success",:output=>"testing is nice",:error=>"",:duration=>1)
    @trd=Rutema::ActiveRecord::Scenario.new(:name=>"TC000_teardown",:attended=>false,:status=>"success",:start_time=>Time.now)
    @trd.steps<<Rutema::ActiveRecord::Step.new(:name=>"echo",:number=>1,:status=>"success",:output=>"testing is nice",:error=>"",:duration=>1)
    @tst=Rutema::ActiveRecord::Scenario.new(:name=>"TC000",:attended=>false,:status=>"success",:start_time=>Time.now)
    @trd.steps<<Rutema::ActiveRecord::Step.new(:name=>"echo",:number=>1,:status=>"success",:output=>"testing is nice",:error=>"",:duration=>1)
    @r=Rutema::ActiveRecord::Run.new
    @r.scenarios=[@stp,@tst,@trd]
    @r.save
  end
  def test_status
    assert_equal(:success,@r.status)
    t1=Rutema::ActiveRecord::Scenario.new(:name=>"failed",:attended=>false,:status=>"error",:start_time=>Time.now)
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
    t1=Rutema::ActiveRecord::Scenario.new(:name=>"failed",:attended=>false,:status=>"error",:start_time=>Time.now)
    t2=Rutema::ActiveRecord::Scenario.new(:name=>"not executed",:attended=>false,:status=>"not_executed",:start_time=>Time.now)
    @tst.stubs(:status).returns("success")
    @r.scenarios<<t1
    @r.scenarios<<t2
    assert_equal(1,@r.number_of_failed)
  end
  def test_number_of_not_executed
    t1=Rutema::ActiveRecord::Scenario.new(:name=>"failed",:attended=>false,:status=>"error",:start_time=>Time.now)
    t2=Rutema::ActiveRecord::Scenario.new(:name=>"not executed",:attended=>false,:status=>"not_executed",:start_time=>Time.now)
    @tst.stubs(:status).returns("success")
    @r.scenarios<<t1
    @r.scenarios<<t2
    assert_equal(1,@r.number_of_not_executed)
  end
end