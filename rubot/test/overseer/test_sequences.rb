$:.unshift File.join(File.dirname(__FILE__),"..","..","lib")
require 'rubygems'
require 'test/unit'
require 'rubot/overseer/sequences.rb'



module TestRubot
  
  class MockRequest
    def request_id
      return 'Build 1'
    end
  end
  
  
  class TestOverseerSequences<Test::Unit::TestCase
    
    def test_shell_script
      script = 'shell "echo #{request.request_id}"'
      sequence = Rubot::Overseer::Sequence.new("sample", script)
      
      cmdSeq = sequence.commands(MockRequest.new)
      assert_equal(1, cmdSeq.steps.size)
      assert_equal("sample_cmdstep_1: echo Build 1 in .", cmdSeq.steps.first.to_s)
    end
    
    def test_shell_script_and_dir
      script = 'shell "cmd", "dir"'
      sequence = Rubot::Overseer::Sequence.new("sample", script)
      
      cmdSeq = sequence.commands(MockRequest.new)
      assert_equal(1, cmdSeq.steps.size)
      assert_equal("sample_cmdstep_1: cmd in dir", cmdSeq.steps.first.to_s)
    end

    def test_shell_script_and_dir
      script = 'ruby do "#{request.request_id}" end'
      sequence = Rubot::Overseer::Sequence.new("rubycode", script)
      
      cmdSeq = sequence.commands(MockRequest.new)
      assert_equal(1, cmdSeq.steps.size)
      assert_equal("Build 1", cmdSeq.steps.first.cmd.call)
      assert_equal("rubycode_rubystep_1", cmdSeq.steps.first.name)
    end    
  end
  
end