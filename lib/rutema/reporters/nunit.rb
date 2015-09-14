#  Copyright (c) 2015 Vassilis Rizopoulos. All rights reserved.
require 'rexml/document'
require_relative "../core/reporter"

module Rutema
  module Reporters
    #The following configuration keys are used by Reporters::NUnit
    #
    # filename - the filename to use to save the report. Default is 'rutema.nunit.xml'
    class NUnit<BlockReporter
      DEFAULT_FILENAME="rutema.nunit.xml"
    
      def initialize configuration,dispatcher
        super(configuration,dispatcher)
        @filename=configuration.reporters.fetch(self.class,{}).fetch("filename",DEFAULT_FILENAME)
      end
      #We get all the data from a test run in here.
      def report specs,states,errors
        tests=[]
        run_status=:success
        number_of_failed=0
        states.each do |k,v|
          tests<<test_case(k,v)
          number_of_failed+=1 if v['status']!=:success
        end

        run_status=:error if number_of_failed>0
        failures=errors.map{|error| failure("In #{error[:test]}\n#{error[:error]}")}
        run_status=:error unless failures.empty?

        #<test-run id="" name="" fullname=""  testcasecount="" 
        #result="" time="" run-date="YYYY-MM-DD" start-time="HH:MM:SS">
        #total="18" passed="12" failed="2" inconclusive="1" skipped="3"
        element_run=REXML::Element.new("test-run")
        element_run.add_attributes("name"=>@configuration.context["config_file"],"testcasecount"=>specs.size,"result"=>nunit_result(run_status),
          "total"=>specs.size,"passed"=>specs.size-number_of_failed-failures.size,"failed"=>number_of_failed,"skipped"=>failures.size)
        
        #<test-suite type="rutema" id="" name="" fullname="" testcasecount="" result="" time="">
        #<failure>
        #  <message></message>
        #</failure>
        element_suite=REXML::Element.new("test-suite")
        element_suite.add_attributes("name"=>@configuration.context["config_file"],"testcasecount"=>specs.size,"result"=>nunit_result(run_status),
          "total"=>specs.size,"passed"=>specs.size-number_of_failed-failures.size,"failed"=>number_of_failed,"skipped"=>failures.size)
        
        failures.each{|t| element_suite.add_element(t)}
        tests.each{|t| element_suite.add_element(t)}
        element_run.add_element(element_suite)
        xmldoc=REXML::Document.new
        xmldoc.add_element(element_run)
        
        File.open(@filename,"wb") {|f| f.write( xmldoc.to_s)}
      end
      private
      def test_case name,state
        #<test-case id="" name="" result="" time="">
        #<failure>
        #  <message></message>
        #</failure>
        #</test-case>
        element_test=REXML::Element.new("test-case")
        element_test.add_attributes( "id"=>name,"name"=>name,"result"=>nunit_result(state['status']),"time"=>state["duration"])
        if state['status']!=:success
          msg="Step #{state["steps"].last["number"]} failed."
          msg<<"\nOut:\n#{state["steps"].last["out"]}" unless state["steps"].last["out"].empty? 
          msg<<"\nErr:\n#{state["steps"].last["err"]}"
          element_test.add_element(failure(msg))
        end
        return element_test
      end

      def nunit_result status
        return "Passed" unless status!=:success
        return "Failed"
      end
      
      def failure message
        failed=REXML::Element.new("failure")
        msg=REXML::Element.new("message")
        msg.text=message
        failed.add_element(msg)
        return failed
      end
    end
  end
end
