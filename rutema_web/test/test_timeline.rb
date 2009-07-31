$:.unshift File.join(File.dirname(__FILE__),"..","lib")
require 'rubygems'
require 'rutema_web/gems'
require 'rutema_web/sinatra'
require 'test/unit'
require 'ostruct'
require 'mocha'


class TestRutemaWeb <Test::Unit::TestCase
  include RutemaWeb::UI::Timeline
  
  def test_timeline_data
    data=timeline_data(mock_runs)
    assert_equal(12,data.size)
    data.each do |k,v|
      assert_equal(12,v.size)
    end
  end
  private 
  def mock_runs
    t=mock()
    runs=[mock(),mock(),mock(),mock(),mock(),mock(),mock(),mock(),mock(),mock(),mock(),mock()]
    runs.each do |r|
      r.stubs(:id).returns(runs.index(r))
      if runs.index(r)/2==0
        r.stubs(:scenarios).returns(mock_scenarios_12+mock_setup_scenarios)
      else
        r.stubs(:scenarios).returns(mock_scenarios_6)
      end
      #      r.stubs(:context).returns({:start_time=>Time.now,:config_file=>"test"})
      #      r.stubs(:status).returns(:success)
      #      r.stubs(:config_file).returns("test")
    end
    return runs
  end

  def mock_scenarios_6
    scenarios=[mock(),mock(),mock(),mock(),mock(),mock()]
    stub_scenario_methods(scenarios)
  end
  def mock_scenarios_12
    scenarios=mock_scenarios_6+[mock(),mock(),mock(),mock(),mock(),mock()]
    stub_scenario_methods(scenarios)
  end
  def mock_setup_scenarios
    scenarios=[mock(),mock()]
    scenarios.each do |sc|
      sc.stubs(:id).returns(scenarios.index(sc)+100)
      sc.stubs(:name).returns("sc_#{scenarios.index(sc)}_setup")
      sc.stubs(:status).returns("success")
    end
  end
  def stub_scenario_methods scenarios
    scenarios.each do |sc|
      sc.stubs(:id).returns(scenarios.index(sc))
      sc.stubs(:name).returns("sc_#{scenarios.index(sc)}")
      sc.stubs(:status).returns("success")
    end
  end
  
end