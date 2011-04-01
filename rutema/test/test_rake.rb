$:.unshift File.join(File.dirname(__FILE__),"..","lib")
require 'test/unit'
require 'rubygems'
require 'rake'
require 'rutema/rake'

module TestRutema
  class TestRakeTask<Test::Unit::TestCase
    def test_rake_task
      t=nil
      assert_nothing_raised() { t=Rutema::RakeTask.new(:config_file=>"rutema.rutema")  }
      assert_not_nil(t)
      assert_equal("rutema", t.rake_task.name)
      assert_equal([], t.rake_task.prerequisites)
      assert_nothing_raised() { t.add_dependency("some_task") }
      assert_equal(["some_task"], t.rake_task.prerequisites)
    end
    
    def test_rake_task_block
      t=nil
      assert_nothing_raised() { t=Rutema::RakeTask.new do |rt|
        rt.name="test"
        rt.config_file="rutema.rutema"
        rt.add_dependency("some_task")
      end  }
      assert_equal("rutema:test", t.rake_task.name)
      assert_equal(["some_task"], t.rake_task.prerequisites)
      assert_nothing_raised() { t.add_dependency(:symbol_task) }
      assert_nothing_raised() { t.add_dependency(:"ns:symbol_task") }
      assert_equal(["some_task","symbol_task","ns:symbol_task"], t.rake_task.prerequisites)
    end
  end
end