#  Copyright (c) 2007-2021 Vassilis Rizopoulos. All rights reserved.

require 'thread'
require_relative 'parser'
require_relative 'reporter'
require_relative 'runner'
require_relative '../version'

module Rutema
  ##
  # Class implementing the inner workflow of rutema
  #
  # This class takes care of instantiating the configured parser, runner and
  # reporters. The reporters then receive event information from the runner
  # through a Dispatcher instance.
  #
  # The full workflow consists of subsequent +parse+, +run+ and +report+ phases
  # and corresponds to one call of the #run method.
  class Engine
    include Messaging

    ##
    # Initialize a new Engine instance and setup all class instances needed for
    # test execution
    #
    # This brings up a parser, the runner and the reporters and wires them up as
    # needed. After completion of this method the instance is ready for test
    # execution by means of the #run method.
    #
    # * +configuration+ - a Configuration instance according to which Engine,
    #   its components and the test run shall be set up
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

    ##
    # Parse the test specifications, execute the test(s) and report the results
    #
    # * +test_identifier+ - an optional identifier of a single test case to be
    #   executed, this cannot be an arbitrary one but must still be contained
    #   in the configured test specification identifiers
    def run test_identifier=nil
      @dispatcher.run!
      # start
      message("start")
      suite_setup,suite_teardown,setup,teardown,tests=*parse(test_identifier)
      if tests.empty?  
        @dispatcher.exit
        raise RutemaError,"No tests to run!"
      else
        # running - at this point all checks are done and the tests are active
        message("running")
        run_scenarios(tests,suite_setup,suite_teardown,setup,teardown)
      end
      message("end")
      @dispatcher.exit
      @dispatcher.report(tests)
    end

    ##
    # Parse a single test specification or all the specs given by the
    # configuration
    #
    # * +test_identifier+ - an optional identifier of a single test case to be
    #   executed, this cannot be an arbitrary one but must still be contained
    #   in the configured test specification identifiers
    def parse test_identifier=nil
      specs=[]
      #so, while we are parsing, we have a list of tests
      #we're either parsing all of the tests, or just one
      #make sure the one test is on the list
      if test_identifier
        if is_spec_included?(test_identifier)
          specs<<parse_specification(File.expand_path(test_identifier))
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

    ##
    # Parse an array of test specifications into Specification instances
    #
    # * +tests+ - an array containing paths to test specification files or the
    #   test specifications' texts themselves
    def parse_specifications tests
      tests.map do |t| 
        parse_specification(t)
      end.compact
    end

    ##
    # Parse a single test specification into a Specification instance
    #
    # * +spec_identifier+ - either the path to a test specification file or the
    #   actual test specification text itself
    #
    # A ParserError is raised upon failure.
    def parse_specification spec_identifier
      begin
        @parser.parse_specification(spec_identifier)
      rescue Rutema::ParserError
        error(spec_identifier,$!.message)
        raise Rutema::ParserError, "In #{spec_identifier}: #{$!.message}" 
      end
    end

    ##
    # Parse the special test (suite) setup and teardown methods if set
    #
    # This returns an array containing Specification instances for
    # * test suite setup
    # * test suite teardown
    # * test setup
    # * test teardown
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

    ##
    # Execute the passed test Specification instances
    #
    # * +specs+ - an array of Specification instances representing the actual
    #   tests
    # * +suite_setup+ - a test suite setup Specification instance
    # * +suite_teardown+ - a test suite teardown Specification instance
    def run_scenarios(specs, suite_setup, suite_teardown, setup, teardown)
      if specs.empty?
        error(nil,"No tests to run")
      else
        @runner.setup = nil
        @runner.teardown = nil

        if !suite_setup || (run_test(suite_setup, true) == :success)
          @runner.setup = setup
          @runner.teardown = teardown
          specs.each{|spec| run_test(spec)}
        else
          error(nil, "Suite setup test failed")
        end
        if suite_teardown
          @runner.setup = nil
          @runner.teardown = nil
          run_test(suite_teardown, true)
        end
      end
    end

    ##
    #
    def run_test(specification, is_special = false)
      if specification.scenario
        status = @runner.run(specification, is_special)["status"]
      else
        status=:not_executed
        message(:test=>specification.name,:text=>"No scenario", :status=>status)
      end
      return status
    end

    ##
    # Instantiate a new class of a given type passing it a given configuration
    # upon construction
    #
    # * +definition+ - class of which a new instance shall be instantiated
    # * +configuration+ - Configuration instance which shall be passed to the
    #   initializer of the to be created instance
    def instantiate_class definition,configuration
      if definition[:class]
        klass=definition[:class]
        return klass.new(configuration)
      end
      return nil
    end

    ##
    # Check if the given test identifier belongs to the normal test cases or to
    # one of the special ones (the test (suite) setups and teardowns)
    #
    # * +test_identifier+ - the test identifier to check against membership in
    #   the normal or special test case identifier sets
    def is_spec_included? test_identifier
      full_path=File.expand_path(test_identifier)
      return @configuration.tests.include?(full_path) || is_special?(test_identifier)
    end

    ##
    # Check if the given test identifier is a (suite) setup or teardown one
    #
    # This checks if the given identifier was configured as (suite) setup or
    # teardown within the rutema run's configuration.
    #
    # * +test_identifier+ - the test identifier which shall be checked for being
    #   a special one
    def is_special? test_identifier
      full_path=File.expand_path(test_identifier)
      return full_path==@configuration.suite_setup ||
      full_path==@configuration.suite_teardown ||
      full_path==@configuration.setup ||
      full_path==@configuration.teardown
    end
  end

  ##
  # Class functioning as a demultiplexer between the Engine and the various
  # Reporters instances
  #
  # In stream mode the incoming queue is popped periodically and the messages
  # are distributed to the queues of any subscribed event reporters. By default
  # this includes Reporters::Collector which is then used at the end of a run to
  # provide the collected data to all registered block mode reporters 
  class Dispatcher
    ##
    # The interval between queue operations
    INTERVAL = 0.01

    ##
    # Initialize a new demultiplexer and instantiate all reporters requested by
    # the passed configuration
    #
    # * +queue+ - the queue which will be shared between the Engine instance and
    #   the Reporter instances
    # * +configuration+ - the Configuration instance of the rutema run
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

    ##
    # Call this to establish a queue with the given identifier
    #
    # This method will create a new queue within the Dispatcher instance into
    # which data from the incoming queue from the Engine instance will be
    # dispatched to.
    #
    # * +identifier+ - a unique identifier for the queue. If two identifiers
    #   collide the new subscriber will replace the earlier one
    def subscribe identifier
      @queues[identifier]=Queue.new
      return @queues[identifier]
    end

    ##
    # Start #update threads of all event/streaming reporters and then start a
    # new locally managed thread which continually dispatches messages from the
    # incoming queue
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

    ##
    # Call all block reporters' BlockReporter#report method
    def report specs
      @block_reporters.each do |r|
        r.report(specs,@collector.states,@collector.errors)
      end
      Reporters::Summary.new(@configuration,self).report(specs,@collector.states,@collector.errors)
    end

    ##
    # Dispatch all messages in the incoming queue to the subscribed reporters,
    # exit all streaming reporters' threads and then stop the own internal
    # dispatch thread
    def exit
      puts "Exiting main dispatcher" if $DEBUG
      if @thread
        flush
        @streaming_reporters.each {|r| r.exit}
        Thread.kill(@thread)
      end
    end

    private

    ##
    # Dispatch messages from the incoming queue to all subscribers until the
    # incoming queue is empty
    def flush
      puts "Flushing queues" if $DEBUG
      if @thread
        while @queue.size>0 do
          dispatch()
          sleep INTERVAL
        end
      end
    end

    ##
    # Instantiate a new reporter instance and pass the configuration and this
    # Dispatcher instance this method is called upon to
    #
    # * +definition+ - hash containing the class type which shall be
    #   instantiated referenced by its +:class+ key
    # * +configuration+ - the Configuration instance which shall be passed to
    #   the initializer of the to be instantiated class
    #
    # This either returns the new class instance or _nil_ if the passed hash
    # did not contain a key +:class+
    def instantiate_reporter definition,configuration
      if definition[:class]
        klass=definition[:class]
        return klass.new(configuration,self)
      end
      return nil
    end

    ##
    # Pop the last element of the incoming queue from the runner (if it's not
    # empty) and distribute it to all subscribed Reporters::EventReporter
    # instances
    def dispatch
      if @queue.size>0
        data=@queue.pop
        @queues.each{ |i,q| q.push(data) } if data
      end
    end
  end
end
