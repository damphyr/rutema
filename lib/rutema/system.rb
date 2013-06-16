#  Copyright (c) 2007-2012 Vassilis Rizopoulos. All rights reserved.
$:.unshift File.join(File.dirname(__FILE__),"..")
require 'patir/command'
require 'patir/base'
require 'rutema/configuration'

require 'rutema/parsers/base'
         
require 'rutema/runners/default'
require 'rutema/runners/step'

require 'rutema/reporters/text'

module Rutema
  #This class coordinates parsing, execution and reporting of test specifications
  class Coordinator
    attr_accessor :configuration,:parse_errors,:parsed_files
    attr_reader :test_states
    def initialize configuration,logger=nil
      @logger=logger
      @logger||=Patir.setup_logger
      @parse_errors=Array.new
      @configuration=configuration
      @parser=instantiate_class(@configuration.parser)
      raise "Could not instantiate parser" unless @parser
      @reporters=@configuration.reporters.collect{ |reporter| instantiate_class(reporter) }
      @reporters.compact!
      #this will hold any specifications that are succesfully parsed.
      @specifications=Hash.new
      @parsed_files=Array.new
      @test_states=Hash.new
    end
    #Runs a set of tests
    #
    #mode can be :all, :attended, :unattended or a test filename
    def run mode
      @runner||=create_runner
      @configuration.context[:start_time]=Time.now
      @logger.info("Run started in mode '#{mode}'")
      begin
        case mode
        when :all
          @runner.attended=true
          specs=parse_all_specifications
          run_scenarios(specs)
        when :attended
          @runner.attended=true
          specs=parse_all_specifications
          run_scenarios(specs.select{|s| s.scenario && s.scenario.attended?})
        when :unattended
          specs=parse_all_specifications
          run_scenarios(specs.select{|s| s.scenario && !s.scenario.attended?})
        when String
          @runner.attended=true
          spec=parse_specification(mode)
          run_test(spec) if spec
        else
          @logger.fatal("Don't know how to run '#{mode}'")
          raise "Don't know how to run '#{mode}'"
        end
      rescue
        @logger.debug($!)
        @logger.fatal("Runner error: #{$!.message}")
        raise 
      end
      @configuration.context[:end_time]=Time.now
      @logger.info("Run completed in #{@configuration.context[:end_time]-@configuration.context[:start_time]}s")
    end
    
    #Parses all specification files defined in the configuration
    def parse_all_specifications
      @configuration.tests.collect do |t| 
        begin
          spec=parse_specification(t)
        rescue
          @logger.debug($!)
          @logger.error($!.message)
        end
      end.compact
    end
    #Delegates reporting to all configured reporters spawning one thread per reporter
    #
    #It then joins the threads and returns when all of them are finished.
    def report
      #get the states from the runner
      @runner.states.each do |k,v|
        if v
          @test_states[k]=v
        else
          @logger.warn("State for #{k} is nil")
        end
      end
      threads=Array.new
      #get the runner stati and the configuration and give it to the reporters
      @reporters.each do |reporter|
        threads<<Thread.new(reporter,@specifications,@test_states.values,@parse_errors,@configuration) do |reporter,specs,status,perrors,configuration|
          begin
            @logger.debug(reporter.report(specs,status,perrors,configuration))
          rescue RuntimeError
            @logger.error("Error in #{reporter.class}: #{$!.message}")
            @logger.debug($!)
          end
        end
      end
      threads.each do |t| 
        @logger.debug("Joining #{t}")
        t.join
      end
    end

    #returns true if all scenarios in the last run were succesful
    def last_run_a_success?
      return @runner.success?
    end
    def to_s#:nodoc:
      "Parsed #{@parsed_files.size} files\n#{TextReporter.new.report(@specifications,@runner.states.values,@parse_errors,@configuration)}"
    end
    private
    def instantiate_class definition
      if definition[:class]
        #add the logger to the definition
        definition[:logger]=@logger
        #add the configuration to the definition
        definition[:configuration]=@configuration
        klass=definition[:class]
        return klass.new(definition)
      end
      return nil
    end

    def create_runner
      setup=nil
      teardown=nil
      if @configuration.setup
        @logger.info("Parsing setup specification from '#{@configuration.setup}'")
        setup=@parser.parse_setup(@configuration.setup).scenario
      end
      if @configuration.teardown
        @logger.info("Parsing teardown specification from '#{@configuration.teardown}'")
        teardown=@parser.parse_teardown(@configuration.teardown).scenario
      end
      if @configuration.use_step_by_step
        @logger.info("Using StepRunner")
        return StepRunner.new(@configuration.context,setup,teardown,@logger)
      else
        return Runner.new(@configuration.context,setup,teardown,@logger)
      end
    end

    def parse_specification spec_identifier
      spec=nil
      begin
        @parsed_files<<spec_identifier
        @parsed_files.uniq!
        spec=@parser.parse_specification(spec_identifier)
        if @specifications[spec.name]
          msg="Duplicate specification name '#{spec.name}' in '#{spec_identifier}'"
          @logger.error(msg)
          @parse_errors<<{:filename=>spec_identifier,:error=>msg}
          @test_states[spec.name]=Patir::CommandSequenceStatus.new(spec.name,[])
        else
          @specifications[spec.name]=spec
          @test_states[spec.name]=Patir::CommandSequenceStatus.new(spec.name,spec.scenario.steps)
        end
      rescue ParserError
        @logger.error("Error parsing '#{spec_identifier}': #{$!.message}")
        @parse_errors<<{:filename=>spec_identifier,:error=>$!.message}
      end
      return spec
    end

    def run_scenarios specs
      specs.compact!
      if specs.empty?
        @logger.error("No tests to run")
      else
        if @configuration.check
          @logger.info("Parsing check test '#{@configuration.check}'")
          spec=parse_specification(@configuration.check)
          if spec
            @logger.info("Running check test '#{spec.to_s}'")
            if run_test(spec,false).success?
              specs.each{|s| run_test(s)}
            else
              @logger.error("Check test failed")
            end
          else
            @logger.error("Error parsing check test")
          end
        else
          specs.each{|s| run_test(s)}
        end
      end
    end
    
    def run_test specification,run_setup=true
      @logger.info("Running #{specification.name} -  #{specification.title}")
      if specification.scenario
        status=@runner.run(specification.name,specification.scenario,run_setup)
      else
        @logger.warn("#{specification.name} has no scenario")
        status=:not_executed
      end
      @test_states[specification.name]=status
      return status
    end
  end
  #The "executioner" application class
  #
  #Parses the commandline, sets up the configuration and launches Cordinator
  class RutemaX
    require  'optparse'
    def initialize command_line_args
      parse_command_line(command_line_args)
      @logger=Patir.setup_logger(@log_file)
      @logger.info("rutema v#{Version::STRING}")
      begin
        raise "No configuration file defined!" if !@config_file
        @configuration=RutemaConfigurator.new(@config_file,@logger).configuration
        @configuration.context[:config_file]=File.basename(@config_file)
        @configuration.use_step_by_step=@step
        Dir.chdir(File.dirname(@config_file)) do 
          @coordinator=Coordinator.new(@configuration,@logger)
          application_flow
        end 
      rescue Patir::ConfigurationException
        @logger.debug($!)
        @logger.fatal("Configuration error '#{$!.message}'")
        raise "Configuration error '#{$!.message}'"
      rescue
        @logger.debug($!)
        @logger.fatal("#{$!.message}")
        raise
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
          @coordinator.run(@configuration.check)
        else
          @logger.fatal("There is no check test defined in the configuration.")
          raise "There is no check test defined in the configuration."
        end
      else
        #run everything
        @coordinator.run(@mode)
      end
      @logger.info("Report:\n#{@coordinator.to_s}")
      @coordinator.report
      if @coordinator.parse_errors.empty? && @coordinator.last_run_a_success?
        @logger.info("All tests successful")
      else
        @logger.warn("Not all tests were successful")
        raise "Not all tests were successful"
      end
    end
  end
end