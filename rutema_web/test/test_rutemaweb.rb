$:.unshift File.join(File.dirname(__FILE__),"..","lib")
require 'test/unit'
require 'ostruct'
require 'rutemaweb/ramaze_controller'
require 'rubygems'
require 'mocha'

class TestRutemaWeb <Test::Unit::TestCase
  ActiveRecord::Base.establish_connection(:adapter  => "sqlite3",:database =>":memory:")

  def test_loading
    controller=nil
    assert_nothing_raised() { controller = Rutema::UI::MainController.new }
    return controller
  end
  def test_run
    cntlr=test_loading
    r=mock()
    r.expects(:id).returns(5).times(2)
    r.stubs(:context).returns({:start_time=>Time.now,:config_file=>"test"})
    r.stubs(:config_file).returns("test")
    r.stubs(:status).returns(:success)
    t=mock()
    t.expects(:to_html).returns("mocked")
    Rutema::Model::Run.expects(:find).returns([r])
    Rutema::Model::Run.expects(:count).returns(1)
    Ruport::Data::Table.expects(:new).returns(t)
    #Check nothing is raised when calling run (with everything mocked)
    assert_nothing_raised(){ cntlr.run}
  end

  def test_runs
    cntlr=test_loading
    mock_12_runs
    #Check nothing is raised when calling run (with everything mocked)
    assert_nothing_raised(){ cntlr.runs}
    return cntlr
  end
  #unit tests for the pagination code of runs
  def test_pagination
    cntlr=test_loading
    mock_12_runs
    #Check nothing is raised when calling run (with everything mocked)
    assert_nothing_raised(){ cntlr.runs(1)}
    return cntlr
  end
  def test_page_number_to_large
    cntlr=test_loading
    mock_12_runs
    #Check nothing is raised when calling run with a page number greater than the available
    assert_nothing_raised(){ cntlr.runs(50)}
  end
  def test_page_number_negative
    cntlr=test_loading
    mock_12_runs
    #Check nothing is raised when calling run with a negative page number greater than the available
    assert_nothing_raised(){ cntlr.runs(-1)}
  end
  def test_page_number_bogus
    cntlr=test_loading
    mock_12_runs
    #Check nothing is raised when calling run with a page number that is not a number
    assert_nothing_raised(){ cntlr.runs("atttaaaaack!!")}
  end

  #unit tests for scenarios
  def test_scenarios
    ctlr=test_loading
    mock_12_scenarios
    Rutema::Model::Run.expects(:find).returns("")
    assert_nothing_raised() { ctlr.scenarios }
  end

  def test_scenario_wrong_arguments
    ctlr=test_loading
    assert_raise(ArgumentError) { ctlr.scenario("bla","blu")  }
  end
  private 
  def mock_12_runs
    t=mock()
    t.expects(:to_html).returns("mocked")
    Ruport::Data::Table.expects(:new).returns(t)
    runs=[mock(),mock(),mock(),mock(),mock(),mock(),mock(),mock(),mock(),mock(),mock(),mock()]
    runs.each do |r|
      r.stubs(:id).returns(5)
      r.stubs(:context).returns({:start_time=>Time.now,:config_file=>"test"})
      r.stubs(:status).returns(:success)
      r.stubs(:config_file).returns("test")
    end
    Rutema::Model::Run.expects(:find).returns(runs)
    Rutema::Model::Run.expects(:count).returns(12)
  end

  def mock_12_scenarios
    t=mock()
    t.expects(:to_html).returns("mocked")
    Ruport::Data::Table.expects(:new).returns(t)
    scenarios=[mock(),mock(),mock(),mock(),mock(),mock(),mock(),mock(),mock(),mock(),mock(),mock()]
    scenarios.each do |sc|
      sc.stubs(:name).returns(scenarios.index(sc).to_s)
      sc.stubs(:status).returns(:success)
      sc.expects(:title).returns(scenarios.index(sc).to_s)
      sc.expects(:run).returns(scenarios.index(sc))
    end
    Rutema::Model::Scenario.stubs(:find).returns(scenarios)
  end
end