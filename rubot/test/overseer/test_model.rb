#  Copyright (c) 2007 Vassilis Rizopoulos. All rights reserved.
$:.unshift File.join(File.dirname(__FILE__),"..","..","lib")
require 'rubygems'
require 'test/unit'
require 'rubot/overseer/model.rb'
require 'patir/base'
#require 'ramaze'
module TestRubot
  class TestModel<Test::Unit::TestCase
    TEST=":memory:"
    ActiveRecord::Base.establish_connection(:adapter=>"sqlite3",:dbfile=>TEST)
    Rubot::Model::Schema.up
    
    def setup
      @prev_dir=Dir.pwd
      Dir.chdir(File.dirname(__FILE__))
      assert_nothing_raised(){Rubot::Model.connect(TEST,Patir.setup_logger)}
    end

    def teardown
      Dir.chdir(@prev_dir)
    end

    def test_model
      request=Rubot::Model::Request.new
      request.request_time=Time.now
      request.worker="test_worker"
      assert_nothing_raised(){request.save}
      run=Rubot::Model::Run.new
      run.start_time=Time.now
      run.sequence_runner="test_worker"
      run.name="test_sequence"
      run.status=:running
      run.request_id=request.id
      request.run=run
      assert_nothing_raised(){request.save}
      step=Rubot::Model::Step.new
    end

    def test_latest_request_from_worker
      worker = "my_worker"
      request_1 = create_request worker
      request_2 = create_request worker

      assert_equal(request_2, Rubot::Model::Request.latest_request_from_worker(worker))
    end

    def create_request worker
      request=Rubot::Model::Request.new
      request.request_time=Time.now
      request.worker=worker
      request.save
      request
    end
  end
  
end