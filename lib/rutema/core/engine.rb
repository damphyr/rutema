#  Copyright (c) 2007-2015 Vassilis Rizopoulos. All rights reserved.
require 'thread'
require_relative 'parser'
require_relative 'reporter'
require_relative 'runner'
require_relative '../version'

module Rutema
  class Engine
    include Messaging
    def initialize configuration
      @queue=Queue.new
      @parser=instantiate_class(configuration.parser,configuration) if configuration.parser
      if configuration.runner
        if configuration.runner[:class]
         @runner=configuration.runner[:class].new(configuration.context,@queue)
        else
          raise RutemaError,"Runner settting overriden, but missing :class"
        end
      else
        @runner=Rutema::Runners::Default.new(configuration.context,@queue)
      end
      raise RutemaError,"Could not instantiate parser" unless @parser
      @dispatcher=Dispatcher.new(@queue,configuration)
      @configuration=configuration
    end
    def run test_identifier=nil
      @dispatcher.run!
      #start
      message("start")
      suite_setup,suite_teardown,setup,teardown,tests=*parse(test_identifier)
      if tests.empty?
        if test_identifier && is_special?(test_identifier)
          run_scenarios([suite_setup],nil)
        else
          @dispatcher.exit
          raise RutemaError,"Did not parse any tests succesfully"
        end
      else
        #running - at this point we've done any and all checks and we're stepping on the gas
        message("running")
        run_scenarios(tests,suite_setup,suite_teardown,setup,teardown)
      end
      message("end")
      @dispatcher.exit
      @dispatcher.report(tests)
    end
    def parse test_identifier=nil
      specs=[]
      #so, while we are parsing, we have a list of tests
      #we're either parsing all of the tests, or just one
      #make sure the one test is on the list
      if test_identifier
        if  is_spec_included?(test_identifier)
          specs<<parse_specification(File.expand_path(test_identifier)) unless is_special?(test_identifier)
        else
          error(File.expand_path(test_identifier),"does not exist in the configuration")  
        end
      else
        specs=parse_specifications(@configuration.tests)
      end
      specs.compact!
      suite_setup,suite_teardown,setup,teardown=parse_specials(@configuration)
      return [suite_setup,suite_teardown,setup,teardown,specs]
    end
    private
    def parse_specifications tests
      tests.map{|t| parse_specification(t)}.compact
    end
    def parse_specification spec_identifier
      begin
        @parser.parse_specification(spec_identifier)
      rescue Rutema::ParserError
        error(spec_identifier,$!.message)
        raise Rutema::ParserError, "In #{spec_identifier}: #{$!.message}" if is_special?(spec_identifier)
        nil
      end
    end
    def parse_specials configuration
      suite_setup=nil
      suite_teardown=nil
      setup=nil
      teardown=nil
      if configuration.suite_setup
        suite_setup=parse_specification(configuration.suite_setup)
      end
      if configuration.suite_teardown
        suite_teardown=parse_specification(configuration.suite_teardown)
      end
      if configuration.setup
        setup=parse_specification(configuration.setup)
      end
      if configuration.teardown
        teardown=parse_specification(configuration.teardown)
      end
      return suite_setup,suite_teardown,setup,teardown
    end
    def run_scenarios specs,suite_setup,suite_teardown,setup,teardown
      if specs.empty?
        error(nil,"No tests to run")
      else
        @runner.setup=nil
        @runner.teardown=nil
 
        if !suite_setup || (run_test(suite_setup, true)==:success)
          @runner.setup=setup
          @runner.teardown=teardown
          specs.each{|spec| run_test(spec)}
        else
          error(nil,"Suite setup test failed")          
        end
        if suite_teardown
          @runner.setup=nil
          @runner.teardown=nil
          run_test(suite_teardown, true)
        end
      end
    end
    def run_test specification, is_special = false
      if specification.scenario
        status=@runner.run(specification, is_special)["status"]
      else
        status=:not_executed
        message(:test=>specification.name,:text=>"No scenario", :status=>status)
      end
      return status
    end
    def instantiate_class definition,configuration
      if definition[:class]
        klass=definition[:class]
        return klass.new(configuration)
      end
      return nil
    end
    
    def is_spec_included? test_identifier
      full_path=File.expand_path(test_identifier)
      return tests.include?(full_path) || is_special?(test_identifier) 
    end

    def is_special? test_identifier
      full_path=File.expand_path(test_identifier)
      return full_path==@configuration.suite_setup ||
      full_path==@configuration.suite_teardown ||
      full_path==@configuration.setup ||
      full_path==@configuration.teardown  
    end
  end
  class Dispatcher
    INTERVAL=0.01
    def initialize queue,configuration
      @queue = queue
      @queues = {}
      @streaming_reporters=[]
      @block_reporters=[]
      @collector=Rutema::Reporters::Collector.new(nil,self)
      if configuration.reporters
        instances=configuration.reporters.values.map{|v| instantiate_reporter(v,configuration) if v[:class] != Reporters::Summary}.compact
        @streaming_reporters,_=instances.partition{|rep| rep.respond_to?(:update)}
        @block_reporters,_=instances.partition{|rep| rep.respond_to?(:report)}
      end
      @streaming_reporters<<@collector
      @configuration=configuration
    end
    def subscribe identifier
      @queues[identifier]=Queue.new
      return @queues[identifier]
    end
    
    def run!
      puts "Running #{@streaming_reporters.size} streaming reporters" if $DEBUG
      @streaming_reporters.each {|r| r.run!}
      @thread=Thread.new do
        while true do
          dispatch()
          sleep INTERVAL
        end
      end
    end

    def report specs
      @block_reporters.each do |r|
        r.report(specs,@collector.states,@collector.errors)
      end
      Reporters::Summary.new(@configuration,self).report(specs,@collector.states,@collector.errors)
    end
    def exit
      puts "Exiting main dispatcher" if $DEBUG
      if @thread
        flush
        @streaming_reporters.each {|r| r.exit}
        Thread.kill(@thread)
      end
    end
    private
    def flush
      puts "Flushing queues" if $DEBUG
      if @thread
        while @queue.size>0 do
          dispatch()
          sleep INTERVAL
        end
      end
    end
    def instantiate_reporter definition,configuration
      if definition[:class]
        klass=definition[:class]
        return klass.new(configuration,self)
      end
      return nil
    end
    def dispatch
      if @queue.size>0
        data=@queue.pop
        @queues.each{ |i,q| q.push(data) } if data
      end
    end
  end
end