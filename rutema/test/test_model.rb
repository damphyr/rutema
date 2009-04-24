$:.unshift File.join(File.dirname(__FILE__),"..","lib")

require 'test/unit'
require 'rutema/model'
require 'fileutils'
require 'rubygems'
require 'active_record/fixtures'

module TestRutema
  class TestModel<Test::Unit::TestCase
    def setup
      if RUBY_PLATFORM =~ /java/ 
        ActiveRecord::Base.establish_connection(:adapter  => "jdbch2",:database =>"db/h2")
      else
        ActiveRecord::Base.establish_connection(:adapter  => "sqlite3",:database =>":memory:")
      end
      Rutema::Model::Schema.up
    end
    def teardown
      ActiveRecord::Base.remove_connection
      FileUtils.rm_rf("db/") if File.exists?("db/")
    end
    #test the CRUD operations
    def test_create_read_update_delete
      #create
      r=Rutema::Model::Run.new
      context={:tester=>"automatopoulos",:version=>"latest"}
      r.context=context
      sc=Rutema::Model::Scenario.new(:name=>"TC000",:attended=>false,:status=>"success",:start_time=>Time.now)
      sc.steps<<Rutema::Model::Step.new(:name=>"echo",:number=>1,:status=>"success",:output=>"testing is nice",:error=>"",:duration=>1)
      r.scenarios<<sc
      assert(r.save, "Failed to save.")
      #read
      run=Rutema::Model::Run.find(r.id)
      assert_equal(context,run.context)
      assert_equal(sc.name, run.scenarios[0].name)
      #update
      new_context={:tester=>"tempelopoulos"}
      run.context=new_context
      assert(run.save, "Failed to update.")
      #delete
      assert(run.destroy, "Failed to delete.")
      assert_raise(ActiveRecord::RecordNotFound) {Rutema::Model::Run.find(r.id)}
    end
  end
end