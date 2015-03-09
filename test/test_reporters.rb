# require 'test/unit'
# require 'ostruct'
# require 'fileutils'
# require_relative '../lib/rutema/reporters/base'
# require_relative '../lib/rutema/reporters/text'
# require 'mocha/setup'
# #$DEBUG=true
# module TestRutema
#   class MockCommand
#     include Patir::Command
#     def initialize number
#       @number=number
#     end
#   end

#   class TestTextReporter<Test::Unit::TestCase
#       def setup
#         @parse_errors=[{:filename=>"f.spec",:error=>"error"}]
#         st=Patir::CommandSequenceStatus.new("test_seq")
#         st.step=MockCommand.new(1)
#         st.step=MockCommand.new(2)
#         st.step=MockCommand.new(3)
#         @status=[st]
#       end
      
#       def test_no_errors
#         spec=mock
#         spec.stubs(:title).returns("T")
#         r=Rutema::TextReporter.new
#         assert_nothing_raised() { puts r.report({"0"=>spec},[runner_state_mock],[],nil) }
#       end
      
#       def test_a_bit_of_everything
#         spec=mock
#         spec.stubs(:title).returns("T")
#         r=Rutema::TextReporter.new
#         assert_nothing_raised() { puts r.report({"1"=>spec,"0"=>spec},[runner_state_mock,runner_state_mock(1,:success)],[],nil)}
#       end
      
#       def scenario_mock id,no_summary=false
#         ret = mock()
#         ret.expects(:sequence_id).returns(id)
#         ret.expects(:sequence_name).returns("test").times(2)
#         ret.expects(:summary).returns("summary") unless no_summary
#         return ret
#       end
      
#       def runner_state_mock n=0,status=:success,step_states=[]
#         rs=mock()
#         rs.expects(:sequence_name).returns("#{n}").times(3)
#         rs.expects(:sequence_id).returns("seq_id#{n}")
#         rs.expects(:status).returns(status).times(4)
#         rs.expects(:summary).returns("summary")
#         return rs
#       end
#   end
# end