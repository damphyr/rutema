#  Copyright (c) 2007 Vassilis Rizopoulos. All rights reserved.
$:.unshift File.join(File.dirname(__FILE__),"..","..","lib")
require 'rubygems'
require 'test/unit'
require 'rubot/overseer/loader.rb'
require 'patir/command'

module TestRubot
  
  class TestExtensionLoader<Test::Unit::TestCase
    def test_load_extensions
      Dir.chdir(File.dirname(__FILE__)) do
          exts=Rubot::Overseer.load_extensions("samples/sequences","seq")
          assert_equal(2, exts.size)
          assert_not_nil(exts["sample_sequence"])
          exts=Rubot::Overseer.load_extensions("samples/workers","worker")
          assert_equal(1, exts.size)
          assert_not_nil(exts["sample_worker"])
          exts=Rubot::Overseer.load_extensions("samples/rules","rule")
          assert_equal(1, exts.size)
          assert_not_nil(exts["sample_rule"])
          assert(Rubot::Overseer.load_extensions("samples/","rule").empty?, "Rules in samples")
      end
    end
  end
  
  class TestRuleExtension<Test::Unit::TestCase
    def test_load
      Dir.chdir(File.dirname(__FILE__)) do
        ext=Rubot::Overseer::RuleExtension.new("samples")
        r=eval(File.read("samples/rules/sample_rule.rule"),ext.get_binding)
        assert_not_nil(r)
        assert_equal(["sample_worker"], r.workers)
        assert_equal("sample_sequence", r.sequence)
        assert_equal(r, ext.rule)
      end
    end
    def test_errors
       Dir.chdir(File.dirname(__FILE__)) do
          ext=Rubot::Overseer::RuleExtension.new("samples")
          #missing worker
          assert_raise(Rubot::Overseer::ExtensionError) do
            r=eval("on \"bogus\" do match :branch=>\"g\" end",ext.get_binding)
          end
          #no sequence
          assert_raise(Rubot::Overseer::ExtensionError) do
            r=eval("on \"sample_worker\" do match :branch=>\"g\" end",ext.get_binding)
          end
          #no match rules
          assert_raise(Rubot::Overseer::ExtensionError) do
            r=eval("on \"sample_worker\" do  end",ext.get_binding)
          end
          #missing sequence
          assert_raise(Rubot::Overseer::ExtensionError) do
            r=eval("on \"sample_worker\" do match :branch=>\"b\";with_sequence \"g\" end",ext.get_binding)
          end
        end
    end
  end
  
  class TestWorkerExtension<Test::Unit::TestCase
    def test_load
      ext=Rubot::Overseer::WorkerExtension.new("worker")
      w=eval("ip \"127.0.0.1\";port 3333",ext.get_binding)
      assert_equal("127.0.0.1", w[:ip])
      assert_equal("worker", w[:name])
      assert_equal(3333, w[:port])
      assert_equal(w, ext.worker)
    end
  end
  
  class TestSequenceExtension<Test::Unit::TestCase
    def test_load
      req=OpenStruct.new(:request_id=>1)
      ext=Rubot::Overseer::SequenceExtension.new("sample_sequence",req)
      w=eval('shell "echo #{request.request_id}"',ext.get_binding)
      assert_equal(Patir::CommandSequence, w.class)
    end
  end
end