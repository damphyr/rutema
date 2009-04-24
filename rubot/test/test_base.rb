#  Copyright (c) 2007 Vassilis Rizopoulos. All rights reserved.

$:.unshift File.join(File.dirname(__FILE__),"..","lib")
require 'rubygems'
require 'test/unit'
require 'ostruct'
require 'rubot/base'

module TestRubot
  class TestChange<Test::Unit::TestCase
    def test_new
      chg=Rubot::Change.new({})
      assert_equal("",chg.branch)
      assert_equal("",chg.repository)
      assert(chg.changeset.empty?, "Changeset not empty")
      assert_equal("HEAD", chg.revision)
      
      chg=Rubot::Change.new(:branch=>"b",
        :repository=>"r")
      assert_equal("b", chg.branch)
      assert_equal("r", chg.repository)
      assert(chg.changeset.empty?, "Changeset not empty")
    end
    def test_add_file_change
      chg=Rubot::Change.new(:branch=>"b",
        :repository=>"r")
      assert(chg.changeset.empty?, "Changeset not empty")
      f=Rubot::FileChange.new("me","dir/file","","1")
      chg.add_file_change(f)
      assert_equal(1, chg.changeset.size)
      assert_equal(chg.changeset[0], f)  
      assert_equal("1",chg.revision)
    end
    
    def test_authors
      chg=Rubot::Change.new(:branch=>"b",
        :repository=>"r")
      chg.add_file_change(Rubot::FileChange.new("me","dir/file","","1"))
      assert_equal(["me"], chg.authors)
      chg.add_file_change(Rubot::FileChange.new("you","dir/file","","2"))
      chg.add_file_change(Rubot::FileChange.new("you","dir/file","","4"))
      assert_equal(["me","you"], chg.authors)
    end
    
    def test_revision
      chg=Rubot::Change.new(:branch=>"b",
        :repository=>"r")
      chg.add_file_change(Rubot::FileChange.new("me","dir/file","","1"))
      chg.add_file_change(Rubot::FileChange.new("me","dir/file","","2"))
      assert_equal("2",chg.revision)
      chg.add_file_change(Rubot::FileChange.new("me","dir/file","","5"))
      assert_equal("5",chg.revision)
    end
  end
  
  class TestFileChange<Test::Unit::TestCase
    def test_new
      f=Rubot::FileChange.new("me","dir/file","","1")
      assert_equal("me", f.author)
      assert_equal("dir/file", f.filename)
      assert_equal("", f.comment)
      assert_equal("1", f.revision)
    end
  end
  
  class TestRule<Test::Unit::TestCase
    def test_branch
      assert_raise(RuntimeError) { Rubot::Rule.new(:branch=>"b")  }
      rule=Rubot::Rule.new(:workers=>["worker"],:branch=>"b",:builder=>"b",:sequence=>"s")
      assert(rule.matches?(:branch=>"b"))
      assert(!rule.matches?(:branch=>"c"))
      assert(!rule.matches?(:repository=>"b"))
    end
  
    def test_pattern
      rule=Rubot::Rule.new(:workers=>["worker"],:pattern=>"some",:builder=>"b",:sequence=>"s")
      assert(rule.matches?(:filename=>"some"),"some should match")
      assert(rule.matches?(:filename=>"something"),"something should match")
    end
  
    def test_and
      rule=Rubot::Rule.new(:workers=>["worker"],:pattern=>"some",:branch=>"b",:operator=>:and,:builder=>"b",:sequence=>"s")
      assert(rule.matches?(:branch=>"b",:filename=>"some"))
      assert(!rule.matches?(:filename=>"some"))
      assert(!rule.matches?(:branch=>"b"))
    end
    
    def test_eql
      rule=Rubot::Rule.new(:workers=>["worker"],:pattern=>"some",:branch=>"b",:builder=>"b",:sequence=>"s")
      rule2=Rubot::Rule.new(:workers=>["worker"],:pattern=>"some",:branch=>"b",:builder=>"b",:sequence=>"s")
      assert(!rule.equal?(rule2), "same object")
      assert(rule==rule2)
    end
  end
  
  class TestBuildRequest<Test::Unit::TestCase
    def test_new
      req=Rubot::BuildRequest.new("n")
      assert_equal("n", req.worker)
      assert_nil(req.change)
      req=Rubot::BuildRequest.new("n",Rubot::Change.new(:branch=>"b",:repository=>"r"))
    end
  end
  
end