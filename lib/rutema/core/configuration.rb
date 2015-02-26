  #  Copyright (c) 2007-2015 Vassilis Rizopoulos. All rights reserved.
  require 'ostruct'
  require 'patir/configuration'
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
    module RutemaConfiguration
      #Adds a hash of values to the tools hash of the configuration
      #
      #This hash is then accessible in the parser and reporters as a property of the configuration instance
      #
      #Required keys:
      # :name - the name to use for accessing the path in code
      #Example:
      # configuration.tool={:name=>"nunit",:path=>"/bin/nunit",:configuration=>{:important=>"info"}}
      #
      #The path to make can be accessed in the parser as
      # @configuration.tools.nunit[:path]
      #
      #This way you can pass configuration information for the tools you use
      def tool= definition
        @tools||=Hash.new
        raise Patir::ConfigurationException,"required key :name is missing from #{definition}" unless definition[:name]
        @tools[definition[:name]]=definition
      end
      #Adds a path to the paths hash of the configuration
      #
      #Required keys:
      # :name - the name to use for accessing the path in code
      # :path - the path
      #Example:
      # configuration.path={:name=>"sources",:path=>"/src"}
      def path= definition
        @paths||=Hash.new
        raise Patir::ConfigurationException,"required key :name is missing from #{definition}" unless definition[:name]
        raise Patir::ConfigurationException,"required key :path is missing from #{definition}" unless definition[:path]
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
      
      #Path to the check specification. (optional)
      #
      #The check test runs once in the beginning before all the tests.
      #
      #If it fails no tests are run.
      def check= path
        @check=check_path(path)
      end
      
      #Hash values for passing data to the system. It's supposed to be used in the reporters and contain 
      #values such as version numbers, tester names etc.
      def context= definition
        @context||=Hash.new
        raise Patir::ConfigurationException,"Only accepting hash values as context_data" unless definition.kind_of?(Hash)
        definition.each{ |k,v| @context[k]=v}
      end
      
      #Adds the specification identifiers available to this instance of Rutema
      #
      #These will usually be files, but they can be anything.
      #Essentially this is an Array of strings that mean something to your parser
      def tests= array_of_identifiers
        @tests||=Array.new
        @tests+=array_of_identifiers
      end
      
      #A hash defining the parser to use.
      #
      #The hash is passed as is to the parser constructor and each parser should define the necessary configuration keys.
      #
      #The only required key from the configurator's point fo view is :class which should be set to the fully qualified name of the class to use.
      #
      #Example:
      # configuration.parser={:class=>Rutema::MinimalXMLParser}
      def parser= definition
        raise Patir::ConfigurationException,"required key :class is missing from #{definition}" unless definition[:class]
        @parser=definition
      end
      
      #Adds a reporter to the configuration.
      #
      #As with the parser, the only required configuration key is :class and the definition hash is passed to the class' constructor.
      # 
      #Unlike the parser, you can define multiple reporters.
      def reporter= definition
        @reporters||=Array.new
        raise Patir::ConfigurationException,"required key :class is missing from #{definition}" unless definition[:class]
        @reporters<<definition
      end

      private 
      #Checks if a path exists and raises a Patir::ConfigurationException if not
      def check_path path
        path=File.expand_path(path)
        raise Patir::ConfigurationException,"#{path} does not exist" unless File.exists?(path)
        return path
      end
      #Gives back a string of key=value,key=value for a hash
      def definition_string definition
        msg=Array.new
        definition.each{|k,v| msg<<"#{k}=#{v}"}
        return msg.join(",")
      end
    end

    #This class reads a Rutema configuration file
    #
    #See Rutema::RutemaConfiguration for configuration examples and directives
    class RutemaConfigurator<Patir::Configurator
      include RutemaConfiguration
      def initialize config_file
        @reporters=Array.new
        @context=Hash.new
        @paths=Hash.new
        @tools=Hash.new
        @tests=Array.new
        @setup=nil
        @teardown=nil
        @check=nil
        super(config_file)
      end
      
      def configuration
        @configuration=OpenStruct.new
        Dir.chdir(File.dirname(config_file)) do |path|
          @configuration.tools=OpenStruct.new(@tools)
          @configuration.paths=OpenStruct.new(@paths)
          @configuration.setup=@setup
          @configuration.teardown=@teardown
          @configuration.check=@check
          @configuration.context=@context
          @configuration.parser=@parser
          raise Patir::ConfigurationException,"No parser defined" unless @configuration.parser
          raise Patir::ConfigurationException,"Syntax error in parser definition - missing :class" unless @configuration.parser[:class]
          @configuration.reporters=@reporters
          @configuration.tests=@tests.collect{ |t|  File.exists?(t) ? File.expand_path(t) : t }
          @configuration.filename=@config_file
        end
        return @configuration
      end
    end
  end