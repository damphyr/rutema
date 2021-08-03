#  Copyright (c) 2007-2021 Vassilis Rizopoulos. All rights reserved.

  require 'ostruct'
  require_relative 'parser'
  require_relative 'reporter'
  module Rutema
  ##
  # Mix-in module defining all configuration directives available for rutema
  #
  # === Example
  #
  # A configuration file needs at least definitions of which parser to utilize
  # and which tests to run.
  #
  # rutema configuration files are valid Ruby code and can use the full power of
  # the language including _require_ directives.
  #
  #     require "rake/file_list"
  #     
  #     configure do |cfg|
  #       cfg.parser = { :class => Rutema::Parsers::XML }
  #       cfg.tests = FileList['all/of/the/tests/**/*.*']
  #     end
    module ConfigurationDirectives
    ##
    # Hash of context data which may be utilized throughout test runs
    #
    # This could be used for e.g. tester names, version numbers, etc.
    attr_reader :context

    ##
    # Parser class which shall be used to parse test specifications
    attr_reader :parser

    ##
    # A hash of supplementary paths identified by representative names
    attr_reader :paths

    ##
    # A hash mapping reporter classes to supplementary definitions
    attr_accessor :reporters

    ##
    # Runner class which shall be used to execute the tests
    attr_reader :runner

    ##
    # Path to a setup specification which will be run before every test
    # specification (optional)
    attr_reader :setup

    ##
    # Path to a suite setup specification (optional)
    #
    # This will be run before all other test specifications. If it fails no
    # other specifications will be executed.
    attr_reader :suite_setup

    ##
    # Path to a suite teardown specification (optional)
    #
    # This will be run after all other test specifications
    attr_reader :suite_teardown

    ##
    # Path to a teardown specification which will be run after every test
    # specification (optional)
    attr_reader :teardown

    ##
    # Array of (most probably the paths to) the specifications of the tests to
    # be executed
    #
    # In nearly all cases this would contain only paths but generally this can
    # contain any data intelligible by the test specification parser.
    attr_reader :tests

    ##
    # Hash containing data for tools indexed by their names
    attr_reader :tools

    ##
    # Add a hash with arbitrary data concerning one particular tool which can be
    # utilized throughout testing by accessing the +tools+ attribute of classes
    # including this module
    #
    # The hash must include a +:name+ key which will define the key under which
    # the entire passed hash will be stored.
    #
    # New calls only add to the hash. Later calls containing the same +:name+
    # key as earlier ones replace the data these set.
    #
    # === Example
    #
    #     configure do |cfg|
    #       cfg.tool = { :name => "nunit", :path => "/bin/nunit", :configuration => { :important=>"info" } }
    #     end
    #
    # The path to NUnit can be accessed the following way:
    #
    #     @configuration.tools["nunit"][:path]
      def tool= definition
        raise ConfigurationException,"required key :name is missing from #{definition}" unless definition[:name]
        @tools[definition[:name]]=definition
      end

    ##
    # Add a path indexed by a representative name to the paths attribute
    #
    # A hash is expected which contains a representative name under the +:name+
    # key and the path itself under the +:path+ key.
    #
    # New calls only add to the hash. Later calls containing the same +:name+
    # key as earlier ones replace the data these set.
    #
    # === Example
    #
    #     configure do |cfg|
    #       cfg.path = { :name => "doc", :path => "/usr/local/share/doc" }
    #     end
      def path= definition
        raise ConfigurationException,"required key :name is missing from #{definition}" unless definition[:name]
        raise ConfigurationException,"required key :path is missing from #{definition}" unless definition[:path]
        @paths[definition[:name]]=definition[:path]
      end

    ##
    # Path to a setup specification (optional)
    #
    # This setup specification will be run before every test specification.
    #
    # Later calls override earlier ones.
      def setup= path
        @setup=check_path(path)
      end

    ##
    # Path to a teardown specification (optional)
    #
    # This teardown specification will be run after every test specification.
    #
    # Later calls override earlier ones.
      def teardown= path
        @teardown=check_path(path)
      end

    ##
    # Path to a suite setup specification (optional)
    #
    # This suite setup specification is executed once in the beginning of a test
    # run before any other specifications. If it fails no other test
    # specifications are executed.
    #
    # This is aliased as #check= for backwards compatibility.
    #
    # Later calls override earlier ones.
      def suite_setup= path
        @suite_setup=check_path(path)
      end

      alias_method :check,:suite_setup
      alias_method :check=,:suite_setup=

    ##
    # Path to a suite teardown specification (optional)
    #
    # This suite teardown specification is executed once after all other test
    # specifications have been executed.
    #
    # Later calls override earlier ones.
      def suite_teardown= path
        @suite_teardown=check_path(path)
      end

    ##
    # Context information which shall be accessible during test execution
    #
    # Data must be passed in form of a hash. In case of key collisions later
    # calls override existing data of colliding keys.
    #
    # This could be used e.g. to pass data as tester names, version numbers,
    # etc. to the reporters.
      def context= definition
        @context||=Hash.new
        raise ConfigurationException,"Only accepting hash values as context_data" unless definition.kind_of?(Hash)
        @context.merge!(definition)
      end

    ##
    # Add an array of (paths of) test specifications to be executed
    #
    # Usually an array of file paths would be given. Generally the passed array
    # can contain anything intelligible for the parser.
      def tests= array_of_identifiers
        @tests+=array_of_identifiers.map{|f| full_path(f)}
      end

    ##
    # Set the parser class which shall be used to parse test specifications
    #
    # The only required key is +:class+ which should be set to the fully
    # qualified name of the class to be used for parsing.
    #
    # Later calls overwrite earlier ones.
    #
    # === Example
    #
    #     configure do |cfg|
    #      cfg.parser = { :class => Rutema::Parsers::XML }
    #     end
      def parser= definition
        raise ConfigurationException,"required key :class is missing from #{definition}" unless definition[:class]
        @parser=definition
      end

    ##
    # Set the runner which shall be used to execute the tests
    #
    # Upon construction of the runner the context set through the configuration
    # is being passed to the initializer.
    #
    # The only required key is +:class+ which should be set to the fully
    # qualified name of the class as runner.
    #
    # Later calls overwrite earlier ones.
    #
    # === Example
    #
    #     configure do |cfg|
    #      cfg.runner = { :class => Rutema::Runners::Default }
    #     end
      def runner= definition
        raise ConfigurationException,"required key :class is missing from #{definition}" unless definition[:class]
        @runner=definition
      end

    ##
    # Add a reporter for the test execution
    #
    # The only required key is +:class+ which should be set to the fully
    # qualified name of the class to be used for reporting.
    #
    # Multiple reporter classes can be set simultaneously.
    #
    # === Example
    #
    #     configure do |cfg|
    #      cfg.reporters = { :class => Rutema::Reporters::Console }
    #      cfg.reporters = { :class => Rutema::Reporters::JUnit }
    #     end
      def reporter= definition
        raise ConfigurationException,"required key :class is missing from #{definition}" unless definition[:class]
        @reporters[definition[:class]]=definition
      end

    ##
    # Initialize member variables which are needed to process a configuration
      def init
        @reporters={}
        @context={}
        @tests=[]
        @tools=OpenStruct.new
        @paths=OpenStruct.new
      end

      private

    ##
    # Check if the given path exists and raise a ConfigurationException if not
      def check_path path
        path=File.expand_path(path)
        raise ConfigurationException,"#{path} does not exist" unless File.exist?(path)
        return path
      end

    ##
    # Return a string in the form of "key=value,key=value" for a given hash
      def definition_string definition
        msg=Array.new
        definition.each{|k,v| msg<<"#{k}=#{v}"}
        return msg.join(",")
      end

    ##
    # Convert the given filename to an absolute path if the file exists or
    # otherwise return the passed filename as is
      def full_path filename
        return File.expand_path(filename) if File.exist?(filename)
        return filename
      end
    end

  ##
  # Exception which is being raised upon errors concerning configurations passed
  # to rutema
  #
  # This may be caused by e.g.:
  #
  # * a file or path could not be found/does not exist
  # * passed hash arguments being of an unexpected/unhandled type
  # * passed hash arguments missing required keys
    class ConfigurationException<RuntimeError
    end

  ##
  # Class for reading, parsing and representing the configuration for a rutema
  # test run
  #
  # The instance will be passed around during testing and instruct each
  # component which tests to execute how.
  #
  # Rutema::ConfigurationDirectives defines all relevant methods and attributes.
    class Configuration
      include ConfigurationDirectives

    ##
    # The filename of the root configuration file from which the Configuration
    # instance was built
      attr_reader :filename

    ##
    # Create a new instance by parsing the given configuration file
    #
    # * +config_file+ - the configuration file which shall be parsed on
    #   initializing the new instance
      def initialize config_file
        @filename=config_file
        init
        load_configuration(@filename)
      end

    ##
    # Yield the instance itself if a block is given
    #
    # This can be used e.g. in configuration files to execute a block on the
    # Configuration instance itself (e.g. to modify it through the setter
    # methods of the ConfigurationDirectives module).
      def configure
        if block_given?
          yield self
        end
      end

    ##
    # Load and import the configuration from a file
    #
    # This method can be used to chain configuration files together.
    #
    # === Example
    #
    # If there is a configuration file "main.rutema" which contains all the
    # generic directives and several others which modify specific aspects, then
    # the specialized configurations can import the "main.rutema" as follows:
    #
    #     import("main.rutema")
      def import filename
        fnm = File.expand_path(filename)
        if File.exist?(fnm)          
          load_configuration(fnm)
        else
          raise ConfigurationException, "Import error: Can't find #{fnm}"
        end
      end

      private

    ##
    # Load the configuration from the file given by +filename+
    #
    # On many common parsing errors a ConfigurationException is being raised.
      def load_configuration filename
        begin 
          cfg_txt=File.read(filename)
          cwd=File.expand_path(File.dirname(filename))
          # WORKAROUND for ruby 2.3.1
          fname=File.basename(filename)
          # evaluate in the working directory to enable relative paths in
          # configuration
          Dir.chdir(cwd){eval(cfg_txt,binding(),fname,__LINE__)}
        rescue ConfigurationException
          # pass it on, do not wrap again
          raise
        rescue SyntaxError
          # just wrap the exception so we can differentiate
          raise ConfigurationException.new,"Syntax error in the configuration file '#{filename}':\n#{$!.message}"
        rescue NoMethodError
          raise ConfigurationException.new,"Encountered an unknown directive in configuration file '#{filename}':\n#{$!.message}"
        rescue 
          # just wrap the exception so we can differentiate
          raise ConfigurationException.new,"#{$!.message}"
        end
      end
    end
  end
