$:.unshift File.join(File.dirname(__FILE__),"..")
require 'test/unit'
require 'fileutils'
require 'rubygems'
require 'lib/rutema/models/activerecord'

module TestRutema
  class TestActiveRecordModel<Test::Unit::TestCase
    def setup
      ActiveRecord::Base.establish_connection(:adapter  => "sqlite3",:database =>":memory:")
      Rutema::ActiveRecord::Schema.up
    end
    def teardown
      ActiveRecord::Base.remove_connection
      FileUtils.rm_rf("db/") if File.exists?("db/")
    end
    #test the CRUD operations
    def test_create_read_update_delete
      #create
      r=Rutema::ActiveRecord::Run.new
      context={:tester=>"automatopoulos",:version=>"latest"}
      r.context=context
      sc=Rutema::ActiveRecord::Scenario.new(:name=>"TC000",:attended=>false,:status=>"success",:start_time=>Time.now)
      sc.steps<<Rutema::ActiveRecord::Step.new(:name=>"echo",:number=>1,:status=>"success",:output=>"testing is nice",:error=>"",:duration=>1)
      r.scenarios<<sc
      assert(r.save, "Failed to save.")
      #read
      run=Rutema::ActiveRecord::Run.find(r.id)
      assert_equal(context,run.context)
      assert_equal(sc.name, run.scenarios[0].name)
      #update
      new_context={:tester=>"tempelopoulos"}
      run.context=new_context
      assert(run.save, "Failed to update.")
      #delete
      assert(run.destroy, "Failed to delete.")
      assert_raise(ActiveRecord::RecordNotFound) {Rutema::ActiveRecord::Run.find(r.id)}
    end
  end
  
  class TestCouchDBModel<Test::Unit::TestCase
    def setup
      @db=CouchRest.database!("http://localhost:5984/rutema_test")
    end
    
    def test_couchdb_model
      run=Rutema::CouchDB::Run.new
      run.database=@db
      run.context="context"
      run.scenarios=["1","2","#{self.object_id}"]
      assert_nothing_raised() {  run.save }
      
      r=Rutema::CouchDB::Run.get(run.slug)
      assert_equal(run.slug, r.slug)
    end
  end
end