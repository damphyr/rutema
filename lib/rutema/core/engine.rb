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
        @runner=instantiate_class(configuration.runner,configuration) 
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
      check,setup,teardown,tests=*parse(test_identifier)
      if tests.empty?
        @dispatcher.exit
        raise RutemaError,"Did not parse any tests succesfully"
      else
        @runner.setup=setup
        @runner.teardown=teardown
        #running - at this point we've done any and all checks and we're stepping on the gas
        message("running")
        run_scenarios(tests,check)
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
        if @configuration.tests.include?(File.expand_path(test_identifier))
          specs<<parse_specification(File.expand_path(test_identifier))
        else
          error(File.expand_path(test_identifier),"Does not exist in the configuration")  
        end
      else
        specs=parse_specifications(@configuration.tests)
      end
      specs.compact!
      check,setup,teardown=parse_specials(@configuration)
      return [check,setup,teardown,specs]
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
        nil
      end
    end
    def parse_specials configuration
      check=nil
      setup=nil
      teardown=nil
      if configuration.check
        check=parse_specification(configuration.check)
      end
      if configuration.setup
        setup=parse_specification(configuration.setup)
      end
      if configuration.teardown
        teardown=parse_specification(configuration.teardown)
      end
      return check,setup,teardown
    end
    def run_scenarios specs,check
      if specs.empty?
        error(nil,"No tests to run")
      else
        if check
          if run_test(check)==:success
            specs.each{|s| run_test(s)}
          else
            error(nil,"Check test failed")
          end
        else
          specs.each{|spec| run_test(spec)}
        end
      end
    end
    def run_test specification
      if specification.scenario
        status=@runner.run(specification)["status"]
      else
        status=:not_executed
        message(:test=>specification.name,:message=>"No scenario", :status=>status)
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