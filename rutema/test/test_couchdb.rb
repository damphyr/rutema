$:.unshift File.join(File.dirname(__FILE__),"..","lib")
require 'rubygems'
require 'test/unit'
require 'ostruct'
require 'rutema/reporters/couchdb'
require 'patir/command'
require 'mocha'
#$DEBUG=true
module TestRutema
  class MockCommand
    include Patir::Command
    def initialize number
      @number=number
    end
  end
  
  class TestCouchDBReporter<Test::Unit::TestCase
    CFG={:db=>{:url=>"http://localhost:5984", :database=>"rutema_test_sandbox"}}
    def setup
      @parse_errors=[{:filename=>"f.spec",:error=>"error"}]
      st=Patir::CommandSequenceStatus.new("test_seq")
      st.step=MockCommand.new(1)
      st.step=MockCommand.new(2)
      st.step=MockCommand.new(3)
      @status=[st]
    end

    def test_no_errors
      spec=mock
      db=mock
      Rutema::CouchDB.expects(:connect).returns(db)
      db.expects(:save_doc).returns({})
      r=Rutema::CouchDBReporter.new(CFG)
      assert_nothing_raised() { r.report({"test"=>spec},[runner_state_mock()],[],nil) }
    end

    def test_a_bit_of_everything
      spec=mock
      spec.expects(:has_version?).returns(false)
      spec.expects(:title).returns("T")
      spec.expects(:description).returns("cool test")
      db=mock
      Rutema::CouchDB.expects(:connect).returns(db)
      db.expects(:save_doc).returns({})
      
      r=Rutema::CouchDBReporter.new(CFG)
      
      assert_nothing_raised() {  r.report({"1"=>spec},[runner_state_mock,runner_state_mock(1,:error)],[],nil) }
    end

    def runner_state_mock n=0,status=:success,step_states=[]
      rs=mock()
      rs.expects(:sequence_name).returns("#{n}")
      rs.expects(:sequence_id).returns("seq_id#{n}")
      rs.expects(:start_time).returns(Time.now-3600)
      rs.expects(:stop_time).returns(Time.now)
      rs.expects(:status).returns(status)
      rs.expects(:strategy).returns(:attended)
      rs.expects(:step_states).returns(step_states)
      return rs
    end
  end
end