$:.unshift File.join(File.dirname(__FILE__),"..",'lib')
require 'test/unit'
require 'ostruct'
require 'fileutils'
require 'rutema/reporters/base'
require 'rutema/reporters/email'
require 'rutema/reporters/text'
require 'mocha/setup'
#$DEBUG=true
module TestRutema
  class MockCommand
    include Patir::Command
    def initialize number
      @number=number
    end
  end
  class TestEmailReporter<Test::Unit::TestCase
    def setup
      @parse_errors=[{:filename=>"f.spec",:error=>"error"}]
      st=Patir::CommandSequenceStatus.new("test_seq")
      st.step=MockCommand.new(1)
      st.step=MockCommand.new(2)
      st.step=MockCommand.new(3)
      @status=[st]
    end
    
    def test_new
      spec=mock()
      spec.expects(:title).returns("A test sequence")
      specs={"test_seq"=>spec}
      definition={:server=>"localhost",:port=>25,:recipients=>["test"],:sender=>"rutema",:subject=>"test",:footer=>"footer"}
      r=Rutema::EmailReporter.new(definition)
      Net::SMTP.expects(:start).times(2)
      assert_nothing_raised() { puts r.report(specs,@status,@parse_errors,nil) }
      assert_nothing_raised() { puts r.report(specs,[],[],nil) }
    end

    def test_multiple_scenarios
      #The status mocks
      status1=status_mock("test6. Status - error. States 3\nStep status summary:\n\t1:'echo' - success\n\t2:'check' - warning\n\t3:'try' - error",6,"T2",:error)
      
      status2=status_mock("test10. Status - success. States 3\nStep status summary:\n\t1:'echo' - success\n\t2:'check' - success\n\t3:'try' - success",10,"T1",:success)
      status3=status_mock("testNil. Status - success. States 3\nStep status summary:\n\t1:'echo' - success\n\t2:'check' - success\n\t3:'try' - success",nil,nil,:success)
      status4=status_mock("test10s. Status - success. States 3\nStep status summary:\n\t1:'echo' - success\n\t2:'check' - success\n\t3:'try' - success","10s","Setup",:success)
      status5=status_mock("test60. Status - error. States 3\nStep status summary:\n\t1:'echo' - success\n\t2:'check' - warning\n\t3:'try' - error",60,"T1",:error)
      stati=[status1,status2,status3,status4,status5]
      #mock the mailing code
      definition={:server=>"localhost",:port=>25,:recipients=>["test"],:sender=>"rutema",:subject=>"test"}
      r=Rutema::EmailReporter.new(definition)
      Net::SMTP.expects(:start)
      #The specification mocks
      spec1=mock()
      spec1.expects(:title).times(2).returns("T1")
      spec2=mock()
      spec2.expects(:title).returns("T2")
      specs={"T1"=>spec1, "T2"=>spec2}
      assert_nothing_raised() {  puts r.report(specs,stati,@parse_errors,nil) }
    end
    
    def status_mock summary,id,name,state
      ret=mock()
      ret.stubs(:summary).returns(summary)
      ret.stubs(:sequence_id).returns(id)
      if name
        ret.stubs(:sequence_name).returns(name)
      else
        ret.stubs(:sequence_name).returns(name)
      end
      ret.stubs(:status).returns(state)
      return ret
    end
  end

  class TestTextReporter<Test::Unit::TestCase
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
        spec.stubs(:title).returns("T")
        r=Rutema::TextReporter.new
        assert_nothing_raised() { puts r.report({"0"=>spec},[runner_state_mock],[],nil) }
      end
      
      def test_a_bit_of_everything
        spec=mock
        spec.stubs(:title).returns("T")
        r=Rutema::TextReporter.new
        assert_nothing_raised() { puts r.report({"1"=>spec,"0"=>spec},[runner_state_mock,runner_state_mock(1,:success)],[],nil)}
      end
      
      def scenario_mock id,no_summary=false
        ret = mock()
        ret.expects(:sequence_id).returns(id)
        ret.expects(:sequence_name).returns("test").times(2)
        ret.expects(:summary).returns("summary") unless no_summary
        return ret
      end
      
      def runner_state_mock n=0,status=:success,step_states=[]
        rs=mock()
        rs.expects(:sequence_name).returns("#{n}").times(3)
        rs.expects(:sequence_id).returns("seq_id#{n}")
        rs.expects(:status).returns(status).times(4)
        rs.expects(:summary).returns("summary")
        return rs
      end
  end
end