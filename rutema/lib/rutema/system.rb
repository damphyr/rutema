#  Copyright (c) 2007 Vassilis Rizopoulos. All rights reserved.
$:.unshift File.join(File.dirname(__FILE__),"..")
require 'rexml/document'
require 'patir/configuration'
require 'patir/command'
require 'patir/base'
require 'rutema/specification'
require 'rutema/configuration'
require 'rutema/reporters/standard_reporters'

module Rutema
  #This module defines the version numbers for the library
  module Version
    MAJOR=1
    MINOR=0
    TINY=5
    STRING=[ MAJOR, MINOR, TINY ].join( "." )
  end
  #The Elements module provides the namespace for the various modules adding parser functionality
  module Elements
    #Minimal offers a minimal(chic) set of elements for use in specifications
    #
    #These are:
    # echo
    # command
    # prompt
    module Minimal
      #echo prints a message on the screen:
      # <echo text="A meaningful message"/>
      # <echo>A meaningful message</echo>
      def element_echo step
        step.cmd=Patir::RubyCommand.new("echo"){|cmd| cmd.error="";cmd.output="#{step.text}";$stdout.puts(cmd.output) ;:success}
      end
      #prompt asks the user a yes/no question. Answering yes means the step is succesful.
      # <prompt text="Do you want fries with that?"/>
      #
      #A prompt element automatically makes a specification "attended"
      def element_prompt step
         step.attended=true
         step.cmd=Patir::RubyCommand.new("prompt") do |cmd|  
          cmd.output=""
          cmd.error=""
          if HighLine.new.agree("#{step.text}")
            step.output="y"
          else
            raise "n"
          end#if
        end#do rubycommand
      end
      #command executes a shell command
      # <command cmd="useful_command.exe with parameters", working_directory="some/directory"/>
      def element_command step
        raise ParserError,"missing required attribute cmd in #{step}" unless step.has_cmd?
        wd=Dir.pwd
        wd=step.working_directory if step.has_working_directory?
        step.cmd=Patir::ShellCommand.new(:cmd=>step.cmd,:working_directory=>File.expand_path(wd))      
      end
    end
  end
  #Is raised when an error is found in a specification
  class ParserError<RuntimeError
  end

  #Base class that bombs out when used.
  #
  #Initialze expects a hash and as a base implementation assigns :logger as the internal logger.
  #
  #By default the internal logger will log to the console if no logger is provided.
  class SpecificationParser
    attr_reader :configuration
    def initialize params
      @logger=params[:logger]
      @logger||=Patir.setup_logger
      @configuration=params[:configuration]
      @logger.warn("No system configuration provided to the parser") unless @configuration
    end
    
    def parse_specification param
      raise ParserError,"not implemented. You should derive a parser implementation from SpecificationParser!"
    end
  end
  
  #BaseXMLParser encapsulates all the XML parsing code
  class BaseXMLParser<SpecificationParser
    ELEM_SPEC="specification"
    ELEM_DESC="specification/description"
    ELEM_TITLE="specification/title"
    ELEM_SCENARIO="specification/scenario"
    ELEM_REQ="requirement"
    #Parses __param__ and returns the Rutema::TestSpecification instance
    #
    #param can be the filename of the specification or the contents of that file.
    #
    #Will throw ParserError if something goes wrong
    def parse_specification param
      @logger.debug("Loading #{param}")
      begin
        if File.exists?(param)
          #read the file
          txt=File.read(param)
          filename=File.expand_path(param)
        else
          filename=Dir.pwd
          #try to parse the parameter
          txt=param
        end
        spec=parse_case(txt,filename)
        raise "Missing required attribute 'name' in specification element" unless spec.has_name? && !spec.name.empty?
        return spec
      rescue
        @logger.debug($!)
        raise ParserError,"Error loading #{param}: #{$!.message}"
      end
    end
    
    private
    #Parses the XML specification of a testcase and creates the corresponding TestSpecification instance
    def parse_case xmltxt,filename
      #the testspec to return
      spec=TestSpecification.new
      #read the test spec
      xmldoc=REXML::Document.new( xmltxt )
      #validate it
      validate_case(xmldoc)
      #parse it
      el=xmldoc.elements[ELEM_SPEC]
      xmldoc.root.attributes.each do |attr,value|
        add_attribute(spec,attr,value)
      end
      #get the title
      spec.title=xmldoc.elements[ELEM_TITLE].text
      spec.title||=""
      spec.title.strip!
      #get the description
      #strip line feeds, cariage returns and remove all tabs
      spec.description=xmldoc.elements[ELEM_DESC].text
      spec.description||=""
      begin
        spec.description.strip!
        spec.description.gsub!(/\t/,'')  
      end unless spec.description.empty?
      #get the requirements
      reqs=el.elements.select{|e| e.name==ELEM_REQ}
      reqs.collect!{|r| r.attributes["name"]}
      spec.requirements=reqs
      #Get the scenario
      @logger.debug("Parsing scenario element")
      Dir.chdir(File.dirname(filename)) do
        spec.scenario=parse_scenario(xmldoc.elements[ELEM_SCENARIO].to_s) if xmldoc.elements[ELEM_SCENARIO]
      end
      spec.filename=filename
      return spec
    end
    #Validates the XML file from our point of view.
    #
    #Checks for the existence of ELEM_SPEC, ELEM_DESC and ELEM_TITLE and raises ParserError if they're missing.
    def validate_case xmldoc
      raise ParserError,"missing #{ELEM_SPEC} element" unless xmldoc.elements[ELEM_SPEC]
      raise ParserError,"missing #{ELEM_DESC} element" unless xmldoc.elements[ELEM_DESC]
      raise ParserError,"missing #{ELEM_TITLE} element" unless xmldoc.elements[ELEM_TITLE]
    end
    
    #Parses the scenario XML element and returns the Rutema::TestScenario instance
    def parse_scenario xmltxt
      @logger.debug("Parsing scenario from #{xmltxt}")
      scenario=Rutema::TestScenario.new
      xmldoc=REXML::Document.new( xmltxt )
      xmldoc.root.attributes.each do |attr,value|
        add_attribute(scenario,attr,value)
      end
      number=0
      xmldoc.root.elements.each do |el| 
        step=parse_step(el.to_s)
        if step.step_type=="include_scenario"
          included_scenario=include_scenario(step)
          included_scenario.steps.each do |st|
            @logger.debug("Adding included step #{st}")
            number+=1
            st.number=number
            st.included_in=step.file
            scenario.add_step(st)
          end
        else
          number+=1
          step.number=number
          scenario.add_step(step)
        end
      end
      return scenario
    end
    
    #Parses xml and returns the Rutema::TestStep instance
    def parse_step xmltxt
      xmldoc=REXML::Document.new( xmltxt )
      #any step element
      step=Rutema::TestStep.new()
      step.ignore=false
      xmldoc.root.attributes.each do |attr,value|
        add_attribute(step,attr,value)
      end
      step.text=xmldoc.root.text.strip if xmldoc.root.text
      step.step_type=xmldoc.root.name
      return step
    end

    def add_attribute element,attr,value
      @logger.debug("Adding attribute #{attr} with value #{value}")
      if boolean?(value)
        element.attribute(attr,eval(value))
      else
        element.attribute(attr,value)
      end
    end
   
    def boolean? attribute_value
      return true if attribute_value=="true" || attribute_value=="false"
      return false
    end
    
    #handles <include_scenario> elements, adding the steps to the current scenario
    def include_scenario step
      @logger.debug("Including file from #{step}")
      raise ParserError,"missing required attribute file in #{step}" unless step.has_file?
      raise ParserError,"Cannot find #{File.expand_path(step.file)}" unless File.exists?(File.expand_path(step.file))
      #Load the scenario
      step.file=File.expand_path(step.file)
      include_content=File.read(step.file)
      @logger.debug(include_content)
      return parse_scenario(include_content)
    end
  end
  #The ExtensibleXMLParser allows you to easily add methods to handle specification elements.
  #
  #A method element_foo(step) allows you to add behaviour for <foo> scenario elements.
  #
  #The method will receive a Rutema::TestStep instance. 
  class ExtensibleXMLParser<BaseXMLParser
    def parse_specification param
      spec = super(param)
      #change into the directory the spec is in to handle relative paths correctly
      Dir.chdir(File.dirname(File.expand_path(spec.filename))) do |path|
        #iterate through the steps
        spec.scenario.steps.each do |step|
          #do we have a method to handle the element?
          if respond_to?(:"element_#{step.step_type}")
            begin
              self.send(:"element_#{step.step_type}",step)
            rescue
              raise ParserError, $!.message
            end
          end
        end
      end
      return spec
    end
  end
  #MinimalXMLParser offers three runnable steps in the scenarios
  #
  #
  class MinimalXMLParser<ExtensibleXMLParser
    include Rutema::Elements::Minimal
  end

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
      @configuration.tests.collect!{|t| File.expand_path(t)}
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
          @logger.debug(specs)
          run_scenarios(specs)
        when :attended
          @runner.attended=true
          specs=parse_all_specifications
          @logger.debug(specs)
          run_scenarios(specs.select{|s| s.scenario && s.scenario.attended?})
        when :unattended
          specs=parse_all_specifications
          @logger.debug(specs)
          run_scenarios(specs.select{|s| s.scenario && !s.scenario.attended?})
        when String
          @runner.attended=true
          spec=parse_specification(mode)
          @logger.debug("Running #{spec}")
          run_test(spec) if spec
        else
          @logger.fatal("Don't know how to run '#{mode}'")
          exit 1
        end
      rescue
        @logger.debug($!)
        @logger.fatal("Runner error: #{$!.message}")
        exit 1
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
        @test_states[k]=v
      end
      threads=Array.new
      #get the runner stati and the configuration and give it to the reporters
      @reporters.each do |reporter|
        threads<<Thread.new(reporter,@specifications,@test_states.values,@parse_errors,@configuration) do |reporter,specs,status,perrors,configuration|
          @logger.debug(reporter.report(specs,status,perrors,configuration))
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
    def to_s
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
        setup=@parser.parse_specification(@configuration.setup).scenario
      end
      if @configuration.teardown
        @logger.info("Parsing teardown specification from '#{@configuration.teardown}'")
        teardown=@parser.parse_specification(@configuration.teardown).scenario
      end
      if @configuration.use_step_by_step
        @logger.info("Using StepRunner")
        return StepRunner.new(setup,teardown,@logger)
      else
        return Runner.new(setup,teardown,@logger)
      end
    end

    def parse_specification spec_file
      filename=File.expand_path(spec_file)
      if File.exists?(filename)
        begin
          @parsed_files<<filename
          @parsed_files.uniq!
          spec=@parser.parse_specification(spec_file)
          if @specifications[spec.name]
            msg="Duplicate specification name '#{spec.name}' in '#{spec_file}'"
            @logger.error(msg)
            @parse_errors<<{:filename=>spec_file,:error=>msg}
            @test_states[spec.name]=Patir::CommandSequenceStatus.new(spec.name,[])
          else
            @specifications[spec.name]=spec
            @test_states[spec.name]=Patir::CommandSequenceStatus.new(spec.name,spec.scenario.steps)
          end
        rescue ParserError
          @logger.error("Error parsing '#{spec_file}': #{$!.message}")
          @parse_errors<<{:filename=>filename,:error=>$!.message}
        end
      else
        msg="'#{filename}' not found."
        @logger.error(msg)
        @parse_errors<<{:filename=>filename,:error=>msg}
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
            @logger.info("Running check test '#{spec}'")
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

  #Runner executes TestScenario instances and maintains the state of all scenarios run.
  class Runner
    attr_reader :states,:number_of_runs
    attr_accessor :setup,:teardown
    attr_writer :attended

    #setup and teardown are TestScenario instances that will run before and after each call
    #to the scenario.
    def initialize setup=nil, teardown=nil,logger=nil
      @setup=setup
      @teardown=teardown
      @attended=false
      @logger=logger
      @logger||=Patir.setup_logger
      @states=Hash.new
      @number_of_runs=0
    end

    def attended?
      return @attended
    end
    #Runs a scenario and stores the result internally
    #
    #Returns the result of the run as a Patir::CommandSequenceStatus
    def run name,scenario, run_setup=true
      @logger.debug("Starting run for #{name} with #{scenario.inspect}")
      #if setup /teardown is defined we need to execute them before and after
      if @setup && run_setup
        @logger.info("Setup for #{name}")
        @states["#{name}_setup"]=run_scenario("#{name}_setup",@setup)
        @states["#{name}_setup"].sequence_id="s#{@number_of_runs}"
        if @states["#{name}_setup"].executed? 
          #do not execute the scenario unless the setup was succesful
          if @states["#{name}_setup"].success?
            @logger.info("Scenario for #{name}")
            @states[name]=run_scenario(name,scenario)
            @states[name].sequence_id="#{@number_of_runs}"
          end
        end
      else
        @logger.info("Scenario for #{name}")
        @states[name]=run_scenario(name,scenario)
        @states[name].sequence_id="#{@number_of_runs}"
      end
      #no setup means no teardown
      if @teardown && run_setup
        #always execute teardown
        @logger.warn("Teardown for #{name}")
        @states["#{name}_teardown"]=run_scenario("#{name}_teardown",@teardown)
        @states["#{name}_teardown"].sequence_id="#{@number_of_runs}t"
      end
      @number_of_runs+=1
      return @states[name]
    end
    
    #Returns the state of the scenario with the given name.
    #
    #Will return nil if no scenario is found under that name.
    def [](name)
      return @states[name]
    end

    def reset
      @states.clear
      @number_of_runs=0
    end

    #returns true if all the scenarios in the last run were succesful or if nothing was run yet
    def success?
      @success=true
      @states.each  do |k,v|
        @success&=(v.status!=:error)
      end
      return @success
    end
    private
    def run_scenario name,scenario
      state=Patir::CommandSequenceStatus.new(name,scenario.steps)
      begin
        attention_needed=scenario.attended?
        if attention_needed && !self.attended?
          @logger.warn("Attended scenario cannot be run in unattended mode")
          state.status=:warning
        else
          if attention_needed
            state.strategy=:attended
          else
            state.strategy=:unattended
          end
          stps=scenario.steps
          if stps.empty?
            @logger.warn("Scenario #{name} contains no steps")
            state.status=:warning
          else
            stps.each do |s| 
              state.step=run_step(s)
              break if :error==state.status
            end
          end
        end
      rescue  
        @logger.error("Encountered error in #{name}: #{$!.message}")
        @logger.debug($!)
        state.status=:error
      end
      state.stop_time=Time.now
      state.sequence_id=@number_of_runs
      return state
    end
    def run_step step
      @logger.info("Running step #{step.number} - #{step.step_type}")
      if step.has_cmd? && step.cmd.respond_to?(:run)
        step.cmd.run
      else
        @logger.warn("No command associated with step '#{step.step_type}'. Step number is #{step.number}")
      end
      msg=step.to_s
      p step if $DEBUG
      # we might not have a command object
      if step.has_cmd? && step.cmd.executed? && !step.cmd.success?
        msg<<"\n#{step.cmd.output}" unless step.cmd.output.empty?
        msg<<"\n#{step.cmd.error}" unless step.cmd.error.empty?
      end
      if step.status==:error
        if step.ignore?
          @logger.warn("Step failed but result is being ignored!")
          @logger.warn(msg)
          step.status=:success
        else
          @logger.error(msg) 
        end
      else
        @logger.info(msg)
      end
      return step
    end
  end

  #StepRunner halts before every step and asks if it should be executed or not.
  class StepRunner<Runner
    def initialize setup=nil, teardown=nil,logger=nil
      @questioner=HighLine.new
      super(setup,teardown,logger)
    end
    def run_step step
      if @questioner.agree("Execute #{step.to_s}?")
        return super(step)
      else
        msg="#{step.number} - #{step.step_type} - #{step.status}"
        @logger.info(msg)
        return step
      end
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
      @logger.info("rutemax v#{Version::STRING}")
      begin
        raise "No configuration file defined!" if !@config_file
        @configuration=RutemaXConfigurator.new(@config_file,@logger).configuration
        @configuration.context[:config_file]=File.basename(@config_file)
        @configuration.use_step_by_step=@step
        Dir.chdir(File.dirname(@config_file)) do 
          @coordinator=Coordinator.new(@configuration,@logger)
          application_flow
        end 
      rescue Patir::ConfigurationException
        @logger.debug($!)
        @logger.fatal("Configuration error '#{$!.message}'")
        exit 1
      rescue
        @logger.debug($!)
        @logger.fatal("#{$!.message}")
        exit 1
      end
    end
    private
    def parse_command_line args
      args.options do |opt|
        opt.on("Options:")
        opt.on("--debug", "-d","Turns on debug messages") { $DEBUG=true }
        opt.on("--config FILE", "-c FILE",String,"Loads the configuration from FILE") { |@config_file|}
        opt.on("--log FILE", "-l FILE",String,"Redirects the log output to FILE") { |@log_file|}
        opt.on("--check","Runs just the check test"){@check=true}
        opt.on("--step","Runs test cases step by step"){@step=true}
        opt.on("-v", "--version","Displays the version") { $stdout.puts("rutemax v#{Version::STRING}");exit 0 }
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
            if File.exists?(command)
              @mode=File.expand_path(command)
            else
              $stderr.puts "Can't find '#{command}' and it does not match any known commands. Don't know what to do with it."
              exit 1
            end
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
          exit 1
        end
      else
        #run everything
        @coordinator.run(@mode)
      end
      @logger.info("Report:\n#{@coordinator.to_s}")
      @coordinator.report
      if @coordinator.parse_errors.empty? && @coordinator.last_run_a_success?
        @logger.info("All tests successful")
        exit 0
      else
        @logger.warn("Not all tests were successful")
        exit 1
      end
    end
  end
  
end