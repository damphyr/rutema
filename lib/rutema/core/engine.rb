#  Copyright (c) 2007-2013 Vassilis Rizopoulos. All rights reserved.
require 'thread'
require_relative '../parsers/base'
require_relative '../version'

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
        rescue Rutema::RutemaError
          error(t,$!.message)
        end
      end.compact
    end
    def parse_specification spec_identifier
      begin
        spec=@parser.parse_specification(spec_identifier)
      rescue Rutema::RutemaError
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
  #Parses the commandline, sets up the configuration and launches Rutema::Engine
  class App
    require  'optparse'
    def initialize command_line_args
      parse_command_line(command_line_args)
      begin
        raise "No configuration file defined!" if !@config_file
        @configuration=RutemaConfigurator.new(@config_file).configuration
        @configuration.context[:config_file]=File.basename(@config_file)
        @configuration.use_step_by_step=@step
        Dir.chdir(File.dirname(@config_file)) do 
          @engine=Engine.new(@configuration,@logger)
          application_flow
        end 
      rescue Patir::ConfigurationException
        raise "Configuration error '#{$!.message}'"
      end
    end
    private
    def parse_command_line args
      args.options do |opt|
        opt.on("Options:")
        opt.on("--debug", "-d","Turns on debug messages") { $DEBUG=true }
        opt.on("--config FILE", "-c FILE",String,"Loads the configuration from FILE") { |config_file| @config_file=config_file}
        opt.on("--log FILE", "-l FILE",String,"Redirects the log output to FILE") { |log_file| @log_file=logfile}
        opt.on("--check","Runs just the check test"){@check=true}
        opt.on("--step","Runs test cases step by step"){@step=true}
        opt.on("-v", "--version","Displays the version") { $stdout.puts("rutema v#{Version::STRING}");exit 0 }
        opt.on("--help", "-h", "-?", "This text") { $stdout.puts opt; exit 0 }
        opt.on("The commands are:")
        opt.on("\tall - Runs all tests")
        opt.on("\tattended - Runs all attended tests")
        opt.on("\tunattended - Runs all unattended tests")
        opt.on("You can also provide a specification filename in order to run a single test")
        opt.parse!
        #and now the rest
        if args.empty?
          @mode=:unattended
        else
          command=args.shift
          case command
          when "attended"
            @mode=:attended
          when "all"
            @mode=:all
          when "unattended"
            @mode=:unattended
          else
            @mode=command
          end
        end
      end
    end

    def application_flow
      if @check
        #run just the check test
        if @configuration.check
          @engine.run(@configuration.check)
        else
          @logger.fatal("There is no check test defined in the configuration.")
          raise "There is no check test defined in the configuration."
        end
      else
        #run everything
        @engine.run(@mode)
      end
      @logger.info("Report:\n#{@engine.to_s}")
      @engine.report
      if @engine.parse_errors.empty? && @engine.last_run_a_success?
        @logger.info("All tests successful")
      else
        @logger.warn("Not all tests were successful")
        raise "Not all tests were successful"
      end
    end
  end
end