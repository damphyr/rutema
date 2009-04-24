require 'rubygems'
require 'test/unit'
require 'rubot/overseer/main'
require 'rubot/worker/main'

$DEBUG=true
module TestRubot
  class MockWorker
    attr_reader :triggered
    def build req
      @triggered=true unless @triggered
      return true
    end
  end
  class MockStatusHandler
    attr_accessor :worker_stati
    def initialize
      @worker_stati={"w"=>Rubot::Worker::Status.new("w","","")}
    end
  end
  class TestDispatcher<Test::Unit::TestCase
    def setup
      @workers={"w"=>MockWorker.new}
      @status_handler=MockStatusHandler.new()
      @request=OpenStruct.new({:worker=>"w",:request_id=>1})
      @bad_request=OpenStruct.new({:worker=>"wb",:request_id=>2})
    end
    def test_dispatching
      d=Rubot::Overseer::Dispatcher.new(:workers=>@workers,:status_handler=>@status_handler)
      assert(d.build(@request), "Build call failed.")
      assert(@workers["w"].triggered, "Worker not called.")
      @status_handler.worker_stati["w"].status=:offline
      assert(d.build(@request), "Build call failed.")
      assert_equal(1,d.pending_builds.size)
      assert(!d.build(@bad_request), "Build call didn't fail.")
    end
  end
end