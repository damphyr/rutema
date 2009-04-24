$:.unshift File.join(File.dirname(__FILE__),"..","..","lib")
require 'test/unit'
require 'ostruct'
require 'rubot/worker/main'
require 'rubygems'
require 'mocha'
#$DEBUG=true

module TestRubot
  module TestWorker
    #Tests Rubot::Worker::Status
    class TestStatus<Test::Unit::TestCase
      def test_builds
        base=File.expand_path(File.dirname(__FILE__))
        status=Rubot::Worker::Status.new("test_status",File.dirname(__FILE__),"http://some.address:0000")
        assert(status.online?, "Not online")
        assert(status.free?, "Not free")
        assert_equal(base, status.base)
        assert_nil(status.current_build)
        status.current_build="b"
        assert_nil(status.current_build)
        assert(status.free?, "Not free")
        st=mock()
        st.expects(:sequence_runner=)
        st.expects(:completed?).returns(false)
        status.current_build=st
        assert_not_nil(status.current_build)
        assert_nothing_raised() { status.to_s }
        assert(!status.free?, "Free")
      end
    end
    #Tests Rubot::Worker::StatusHandler
    class TestStatusHandler<Test::Unit::TestCase
      def test_init
        intf=mock()
        intf.expects(:worker_status)
        conf=OpenStruct.new(:name=>"test_worker",
        :base=>File.dirname(__FILE__),
        :endpoint=>{:ip=>"localhost",:port=>80},
        :interface=>intf
        )
        assert_nothing_raised() { Rubot::Worker::StatusHandler.new(conf)}
      end
      #Not defining an interface just generates an error message - and status updates are just ignored
      def test_no_interface
        hndlr=nil
        assert_nothing_raised() do 
          hndlr=Rubot::Worker::StatusHandler.new(OpenStruct.new(:name=>"test_worker",
          :base=>File.dirname(__FILE__),
          :logger=>Patir.setup_logger,
          :endpoint=>{:ip=>"localhost",:port=>80})
          )
          assert_nothing_raised() { hndlr.update(:status=>"boohaha") }
        end
      end
      #With a proper interface worker_status and build_status methods are called
      def test_update
        intf=mock()
        intf.expects(:worker_status).times(2)
        intf.expects(:build_status).times(1)
        hndlr=Rubot::Worker::StatusHandler.new(OpenStruct.new(:name=>"test_worker",
        :base=>File.dirname(__FILE__),
        :logger=>Patir.setup_logger,
        :endpoint=>{:ip=>"localhost",:port=>80},
        :interface=>intf)
        )
        st=nil
        assert_nothing_raised() { st=hndlr.update(:status=>"") }
        assert_not_nil(st)
        assert_equal("",st.status)
        
        seq=mock()
        seq.expects(:sequence_runner=)
        assert_nothing_raised() {st=hndlr.update(:sequence_status=>seq) }
        assert_not_nil(st.current_build)
        assert_equal(seq, st.current_build)
        assert_nothing_raised() { st=hndlr.update(:foo=>"bar") }
      end
      def test_update_bogus_sequence
        intf=mock()
        intf.expects(:worker_status)
        hndlr=Rubot::Worker::StatusHandler.new(OpenStruct.new(:name=>"test_worker",
        :base=>File.dirname(__FILE__),
        :logger=>Patir.setup_logger,
        :endpoint=>{:ip=>"localhost",:port=>80},
        :interface=>intf)
        )
        st=nil
        assert_nothing_raised() { st=hndlr.update(:sequence_status=>"s") }
        assert_equal(:online, st.status)
        assert(st.free?, "not free")
        assert(st.online?, "not online")
        assert_not_nil(st)
        assert_nil(st.current_build)
      end
    end
    
    class TestCoordinator<Test::Unit::TestCase
      #Test illegal configuration behaviour by passing nil
      def test_illegal
        assert_raise(Patir::ConfigurationException) { Rubot::Worker::Coordinator.new(nil)}
        assert_raise(Patir::ConfigurationException) { Rubot::Worker::Coordinator.new(OpenStruct.new(:base=>File.dirname(__FILE__))) }
      end
      #Test normal flow for initialization
      def test_init
        conf=mock()
        conf.expects(:name).returns("test_worker")
        conf.expects(:base).returns(File.dirname(__FILE__)).times(3)
        conf.expects(:logger=)
        Rubot::Worker::StatusHandler.expects(:new).with(conf)
        Rubot::Worker::BuildRunner.expects(:new)
        assert_nothing_raised() { Rubot::Worker::Coordinator.new(conf) }
      end
    end
  end
end