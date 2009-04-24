$:.unshift File.join(File.dirname(__FILE__),"..","..","lib")
require 'test/unit'
require 'rubot/overseer/main'
require 'ostruct'
require 'rubygems'
require 'mocha'
module TestRubot
  class TestOverseerStatusHandler<Test::Unit::TestCase
    TEST=":memory:"
    #$DEBUG=true

    def setup
      ActiveRecord::Base.establish_connection(:adapter=>"sqlite3",:dbfile=>":memory:")
      Rubot::Model::Schema.up
      @cfg=mock()
      @cfg.expects(:base).returns(File.dirname(__FILE__))
      @cfg.expects(:database).returns({:filename=>TEST}).times(2)
      @cfg.expects(:logger).returns(nil)
      @cfg.expects(:status_handlers).returns(nil)
      @worker_cfg=mock()
      @worker_cfg.expects(:url).returns("http://localhost/worker")
      sample_data
    end
    def teardown
      ActiveRecord::Base.remove_connection()
    end
    def sample_data
      #some test data
      @worker_status=Rubot::Worker::Status.new("worker",".","http://localhost")
      #the sequence status
      @build_status=Patir::CommandSequenceStatus.new("test_sequence")
      @build_status.start_time=Time.now
      #a fake step
      step=OpenStruct.new({:number=>0,
        :name=>"step 1",
        :status=>:success,
        :exec_time=>10,
        :error=>"",
        :output=>"hola!" })
      #add the step to the status
      @build_status.step=step
      @build_status.sequence_id=1
      #add the build stats to the worker status
      @worker_status.current_build=@build_status
    end
    def test_initialize
      handler=nil
      assert_nothing_raised() { handler= Rubot::Overseer::StatusHandler.new(@cfg,{"worker"=>@worker_cfg}) }
      assert_equal(1, handler.worker_stati.size)
    end
    
    def test_incoming_request
      handler=nil
      handler= Rubot::Overseer::StatusHandler.new(@cfg,{"worker"=>@worker_cfg})
      #push a request
      record_id=nil
      assert_nothing_raised(){record_id=handler.incoming_request(Rubot::BuildRequest.new(@worker_status.name))}
      #a record id must be assigned
      assert_not_nil(record_id)
      #check that the names are set right
      assert_not_nil(handler.worker_stati[@worker_status.name])
      assert_nil(handler.worker_stati[@worker_status.name].current_build)
      assert(handler.worker_status(@worker_status))
      #now it should find it
      assert_not_nil(handler.worker_stati[@worker_status.name])
      assert_not_nil(handler.worker_stati[@worker_status.name].current_build)
      return handler
    end
    
    def test_build_status_update
      handler=test_incoming_request
      #update the build status
      @build_status.start_time=Time.now
      assert(handler.build_status(@build_status), "Updating build status failed.")
      step=Rubot::Model::Step.find(1)
      assert_equal(10, step.duration)
    end
    
    def test_bogus_build_update
      handler=test_incoming_request
      #now change the sequence runner - updating should fail
      @build_status.sequence_runner="bogus"
      assert(!handler.build_status(@build_status), "Update didn't fail for bogus sequence runner.")
    end
    
    def test_persistent_data
      handler=test_incoming_request
      req=Rubot::Model::Request.find(1)
      assert_equal(1, req.run.steps.size)
      handler.build_status(@build_status)
      assert_equal(1, req.run.steps.size)
    end
  
  
  end
end