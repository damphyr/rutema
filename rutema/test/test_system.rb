$:.unshift File.join(File.dirname(__FILE__),"..")
require 'rubygems'
require 'test/unit'
require 'ostruct'
require 'patir/command'
require 'mocha'
require 'lib/rutema/system'
require 'lib/rutema/parsers/xml'

#$DEBUG=true
module TestRutema
  class TestCoordinator<Test::Unit::TestCase
    def setup
      @prev_dir=Dir.pwd
      Dir.chdir(File.dirname(__FILE__))
    end
    def teardown
      Dir.chdir(@prev_dir)
    end
    def test_run
      conf=OpenStruct.new(:parser=>{:class=>Rutema::BaseXMLParser},
      :tools=>{},
      :paths=>{},
      :tests=>["distro_test/specs/sample.spec","distro_test/specs/duplicate_name.spec"],
      :reporters=>[],
      :context=>{})
      coord=nil
      assert_nothing_raised() do 
        coord=Rutema::Coordinator.new(conf)
        coord.run(:all)
        assert_equal(1,coord.parse_errors.size)
        coord=Rutema::Coordinator.new(conf)
        coord.run(:attended)
        assert_equal(1,coord.parse_errors.size)
        coord=Rutema::Coordinator.new(conf)
        coord.run(:unattended)
        assert_equal(1,coord.parse_errors.size)
        coord=Rutema::Coordinator.new(conf)
        coord.run("distro_test/specs/sample.spec")
        assert_equal(0,coord.parse_errors.size)
        coord=Rutema::Coordinator.new(conf)
        coord.run("distro_test/specs/no_title.spec")
        assert_equal(1,coord.parse_errors.size)
      end
      puts coord.to_s if $DEBUG
    end
  end
end