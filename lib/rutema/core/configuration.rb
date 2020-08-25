  #  Copyright (c) 2007-2017 Vassilis Rizopoulos. All rights reserved.
  require 'ostruct'
  require_relative 'parser'
  require_relative 'reporter'
  module Rutema
    #This module defines the "configuration directives" used in the configuration of Rutema
    #
    #Example
    #A configuration file needs as a minimum to define which parser to use and which tests to run.
    #
    #Since rutema configuration files are valid Ruby code, you can use the full power of the Ruby language including require directives
    #
    # require 'rake'
    # configuration.parser={:class=>Rutema::MinimalXMLParser}
    # configuration.tests=FileList['all/of/the/tests/**/*.*']
    module ConfigurationDirectives
      attr_reader :parser,:runner,:tools,:paths,:tests,:context,:setup,:teardown,:suite_setup,:suite_teardown
      attr_accessor :reporters
      #Adds a hash of values to the tools hash of the configuration
      #
      #This hash is then accessible in the parser and reporters as a property of the configuration instance
      #
      #Required keys:
      # :name - the name to use for accessing the path in code
      #Example:
      # configure do |cfg|
      #  cfg.tool={:name=>"nunit",:path=>"/bin/nunit",:configuration=>{:important=>"info"}}
      # end
      #
      #The path to nunit can then be accessed in the parser as
      # @configuration.tools.nunit[:path]
      #
      #This way you can pass configuration information for the tools you use
      def tool= definition
        raise ConfigurationException,"required key :name is missing from #{definition}" unless definition[:name]
        @tools[definition[:name]]=definition
      end
      #Adds a path to the paths hash of the configuration
      #
      #Required keys:
      # :name - the name to use for accessing the path in code
      # :path - the path
      #Example:
      # cfg.path={:name=>"sources",:path=>"/src"}
      def path= definition
        raise ConfigurationException,"required key :name is missing from #{definition}" unless definition[:name]
        raise ConfigurationException,"required key :path is missing from #{definition}" unless definition[:path]
        @paths[definition[:name]]=definition[:path]
      end
      #Path to the setup specification. (optional)
      #
      #The setup test runs before every test.
      def setup= path
        @setup=check_path(path)
      end
      #Path to the teardown specification. (optional)
      #
      #The teardown test runs after every test.    
      def teardown= path
        @teardown=check_path(path)
      end
      #Path to the suite setup specification. (optional)
      #
      #The suite setup test runs once in the beginning of a test run before all the tests.
      #
      #If it fails no tests are run.
      #
      #This is also aliased as check= for backwards compatibility
      def suite_setup= path
        @suite_setup=check_path(path)
      end

      alias_method :check,:suite_setup
      alias_method :check=,:suite_setup=
      #Path to the suite teardown specification. (optional)
      #
      #The suite teardown test runs after all the tests.
      def suite_teardown= path
        @suite_teardown=check_path(path)
      end
      #Hash values for passing data to the system. It's supposed to be used in the reporters and contain 
      #values such as version numbers, tester names etc.
      def context= definition
        @context||=Hash.new
        raise ConfigurationException,"Only accepting hash values as context_data" unless definition.kind_of?(Hash)
        @context.merge!(definition)
      end
      #Adds the specification identifiers available to this instance of Rutema
      #
      #These will usually be files, but they can be anything.
      #Essentially this is an Array of strings that mean something to your parser
      def tests= array_of_identifiers
        @tests+=array_of_identifiers.map{|f| full_path(f)}
      end
      #A hash defining the parser to use.
      #
      #The hash is passed as is to the parser constructor and each parser should define the necessary configuration keys.
      #
      #The only required key from the configurator's point fo view is :class which should be set to the fully qualified name of the class to use.
      #
      #Example:
      # cfg.parser={:class=>Rutema::MinimalXMLParser}
      def parser= definition
        raise ConfigurationException,"required key :class is missing from #{definition}" unless definition[:class]
        @parser=definition
      end
      #A hash defining the runner to use.
      #
      #The hash is passed as is to the runner constructor and each runner should define the necessary configuration keys.
      #
      #The only required key from the configurator's point fo view is :class which should be set to the fully qualified name of the class to use.
      #
      #Example:
      # cfg.runner={:class=>Rutema::Runners::NoOp}
      def runner= definition
        raise ConfigurationException,"required key :class is missing from #{definition}" unless definition[:class]
        @runner=definition
      end
      #Adds a reporter to the configuration.
      #
      #As with the parser, the only required configuration key is :class and the definition hash is passed to the class' constructor.
      # 
      #Unlike the parser, you can define multiple reporters.
      def reporter= definition
        raise ConfigurationException,"required key :class is missing from #{definition}" unless definition[:class]
        @reporters[definition[:class]]=definition
      end
      #:stopdoc
      def init
        @reporters={}
        @context={}
        @tests=[]
        @tools=OpenStruct.new
        @paths=OpenStruct.new
      end
      #:startdoc
      private 
      #Checks if a path exists and raises a ConfigurationException if not
      def check_path path
        path=File.expand_path(path)
        raise ConfigurationException,"#{path} does not exist" unless File.exist?(path)
        return path
      end
      #Gives back a string of key=value,key=value for a hash
      def definition_string definition
        msg=Array.new
        definition.each{|k,v| msg<<"#{k}=#{v}"}
        return msg.join(",")
      end

      def full_path filename
        return File.expand_path(filename) if File.exist?(filename)
        return filename
      end
    end

    class ConfigurationException<RuntimeError
    end
    #The object we pass around after we load the configuration from file
    #
    #All relevant methods are in Rutema::ConfigurationDirectives
    class Configuration
      include ConfigurationDirectives
      attr_reader :filename
      def initialize config_file
        @filename=config_file
        init
        load_configuration(@filename)
      end

      def configure
        if block_given?
          yield self
        end
      end
      #Loads the configuration from a file
      #
      #Use this to chain configuration files together
      #==Example
      #Say you have on configuration file "first.rutema" that contains all the generic directives and several others that change only one or two things. 
      #
      #You can import the first.rutema file in the other configurations with
      # import("first.rutema")
      def import filename
        fnm = File.expand_path(filename)
        if File.exist?(fnm)          
          load_configuration(fnm)
        else
          raise ConfigurationException, "Import error: Can't find #{fnm}"
        end
      end

      private
      def load_configuration filename
        begin 
          cfg_txt=File.read(filename)
          cwd=File.expand_path(File.dirname(filename))
          #WORKAROUND for ruby 2.3.1
          fname=File.basename(filename)
          #evaluate in the working directory to enable relative paths in configuration
          Dir.chdir(cwd){eval(cfg_txt,binding(),fname,__LINE__)}
        rescue ConfigurationException
          #pass it on, do not wrap again
          raise
        rescue SyntaxError
          #Just wrap the exception so we can differentiate
          raise ConfigurationException.new,"Syntax error in the configuration file '#{filename}':\n#{$!.message}"
        rescue NoMethodError
          raise ConfigurationException.new,"Encountered an unknown directive in configuration file '#{filename}':\n#{$!.message}"
        rescue 
          #Just wrap the exception so we can differentiate
          raise ConfigurationException.new,"#{$!.message}"
        end
      end
    end
  end