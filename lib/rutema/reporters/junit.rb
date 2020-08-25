#  Copyright (c) 2015 Vassilis Rizopoulos. All rights reserved.
require 'rexml/document'
require_relative "../core/reporter"

module Rutema
  module Reporters
    #This reporter generates an JUnit style XML result file that can be parsed by CI plugins
    #
    #It has been tested with Jenkins (>1.6.20)
    #
    #The following configuration keys are used by Rutema::Reporters::JUnit
    #
    # filename - the filename to use when saving the report. Default is 'rutema.results.junit.xml'
    #
    #Example configuration:
    #
    # require "rutema/reporters/junit"
    # cfg.reporter={:class=>Rutema::Reporters::JUnit,"filename"=>"rutema.junit.xml"}
    class JUnit<BlockReporter
      DEFAULT_FILENAME="rutema.results.junit.xml"
    
      def initialize configuration,dispatcher
        super(configuration,dispatcher)
        @filename=configuration.reporters.fetch(self.class,{}).fetch("filename",DEFAULT_FILENAME)
      end
      #We get all the data from a test run in here.
      def report specs,states,errors
        cnt=process_data(specs,states,errors)
        Rutema::Utilities.write_file(@filename,cnt)
      end
      def process_data specs,states,errors
        tests=[]
        number_of_failed=0
        total_duration=0
        states.each do |k,v|
          tests<<test_case(k,v)
          number_of_failed+=1 if v.status!=:success
          total_duration+=v.duration.to_f
        end
        #<testsuite disabled="0" errors="0" failures="1" hostname="" id=""
        #name="" package="" skipped="" tests="" time="" timestamp="">
        attributes={"id"=>@configuration.context[:config_name],
          "name"=>@configuration.context[:config_name],
          "errors"=>errors.size,
          "failures"=>number_of_failed,
          "tests"=>specs.size,
          "time"=>total_duration,
          "timestamp"=>@configuration.context[:start_time]
        }
        return junit_content(tests,attributes,errors)
      end
      private
      def test_case name,state
        #<testcase name="" time="">      => the results from executing a test method
        #  <system-out>  => data written to System.out during the test run
        #  <system-err>  => data written to System.err during the test run
        #  <skipped/>    => test was skipped
        #  <failure>     => test failed
        #  <error>       => test encountered an error
        #</testcase>
        element_test=REXML::Element.new("testcase")
        element_test.add_attributes("name"=>name,"time"=>state.duration,"classname"=>@configuration.context[:config_name])
        if state.status!=:success
          failed_steps = state.steps.select {|step| !step.status.nil? && STATUS_CODES.find_index(:success) < STATUS_CODES.find_index(step.status)}
          if !failed_steps.empty?
            failed_steps.each do |step|
              fail=REXML::Element.new("failure")          
              fail.add_attribute("message","Step: #{step.text} reported non-success status: #{step.status}.")
              fail.add_text "Step #{step.number} failed."
              element_test.add_element(fail)
              out=REXML::Element.new("system-out")
              out.add_text step.out
              element_test.add_element(out)
              err=REXML::Element.new("system-err")
              err.add_text step.err
              element_test.add_element(err)
            end
          else
            fail.add_attribute("message","Case reported non-success status: #{state.status} without a matching step state.")
            fail.add_text "Case with #{state.steps.last.number} steps failed with no matching failed step."
            element_test.add_element(fail)
            out=REXML::Element.new("system-out")
            out.add_text state.steps.last.out
            element_test.add_element(out)
            err=REXML::Element.new("system-err")
            err.add_text state.steps.last.err
            element_test.add_element(err)          
          end
        end
        return element_test
      end
      def crash name,message
        failed=REXML::Element.new("testcase")
        failed.add_attributes("name"=>name,"classname"=>@configuration.context[:config_name],"time"=>0)
        msg=REXML::Element.new("error")
        msg.add_attribute("message",message)
        msg.add_text message
        failed.add_element(msg)
        return failed
      end
      def junit_content tests,attributes,errors
        element_suite=REXML::Element.new("testsuite")
        element_suite.add_attributes(attributes)        
        errors.each{|error| element_suite.add_element(crash(error.test,error.text))}
        tests.each{|t| element_suite.add_element(t)}
        return document(element_suite).to_s
      end
      def document suite
        xmldoc=REXML::Document.new
        xmldoc<<REXML::XMLDecl.new
        xmldoc.add_element(suite)
        return xmldoc
      end
    end
  end
end
