#  Copyright (c) 2007-2013 Vassilis Rizopoulos. All rights reserved.
require 'thread'
require 'rutema/parsers/base'

module Rutema
  module Messaging
    def error identifier,message
      message(:test=>identifier,:error=>message,:timestamp=>Time.now)
    end
    def message message
      message[:timestamp]=Time.now
      @queue.push(message)
    end
  end
  class RutemaError<RuntimeError
  end
  class Engine
    include Messaging
    def initialize configuration
      @configuration=configuration
      @parser=instantiate_class(configuration.parser) if @configuration.respond_to?(:parser)
      @runner=instantiate_class(configuration.runner) if @configuration.respond_to?(:runner)
      raise RutemaError,"Could not instantiate parser" unless @parser
      raise RutemaError,"Could not instantiate runner" unless @runner
      @queue=Queue.new
      @dispatcher=Dispatcher.new(@queue,@configuration)
    end
    def run test_identifier=nil
      @dispatcher.run!
      #start
      message(:message=>"start")
      check,setup,teardown,tests=*parse(test_identifier)
      @runner.setup=setup
      @runner.teardown=teardown
      #running - at this point we've done any and all checks and we're stepping on the gas
      message(:message=>"running")
      run_scenarios(tests,check)
      #
      message(:message=>"end")
      @dispatcher.exit
    end
    def parse test_identifier=nil
      specs=[]
      #so, while we are parsing, we have a list of tests
      #we're either parsing all of the tests, or just one
      #make sure the one test is on the list
      if test_identifier
        if @configuration.tests.include?(test_identifier)
          specs<<parse_specification(t)
        else
          error(test_identifier,"Does not exist in the configuration")  
        end
      else
        specs=parse_specifications(@configuration.tests)
      end
      check,setup,teardown=parse_specials(@configuration)
      return [check,setup,teardown,specs]
    end
    private
    def parse_specifications tests
      tests.collect do |t| 
        begin
          parse_specification(t)
        rescue Rutema::ParserError
          error(t,$!.message)
        end
      end.compact
    end
    def parse_specification spec_identifier
      begin
        spec=@parser.parse_specification(spec_identifier)
      rescue Rutema::ParserError
        error(spec_identifier,$!.message)
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
          if run_test(check).success?
            specs.each{|s| run_test(s)}
          else
            error(nil,"Check test failed")
          end
        else
          specs.each{|s| run_test(s)}
        end
      end
    end
    def run_test specification
      if specification.scenario
        status=@runner.run(specification.name,specification.scenario)
      else
        message(:test=>specification.name,:message=>"No scenario")
        status=:not_executed
      end
      message(:test=>specification.name,:status=>status)
      return status
    end
    def instantiate_class definition
      if definition[:class]
        klass=definition[:class]
        return klass.new(@configuration)
      end
      return nil
    end
  end
  class Dispatcher
    INTERVAL=0.1
    def initialize queue,configuration
      @queue = queue
      @queues = {}
      @streaming_reporters,@block_reporters=configuration.reporters.collect{ |r| instantiate_reporter(r) }.compact.partition{|rep| rep.respond_to?(:update)}
    end
    def subscribe identifier
      @queues[identifier]=Queue.new
      return @queues[identifier]
    end
    def run! 
      counter=0
      @streaming_reporters.each {|r| r.run!}
      @thread=Thread.new do
                while true do
                  dispatch()
                  sleep INTERVAL
                end
            end
        end
    def exit
      if @thread
        while @queue.size>0 do
          dispatch()
          sleep INTERVAL
        end
        @streaming_reporters.each {|r| r.exit}
        Thread.kill(@thread)
      end
    end
    private
    def instantiate_reporter definition
      if definition[:class]
        klass=definition[:class]
        return klass.new(@configuration,self)
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