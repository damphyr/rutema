# Copyright (c) 2007-2020 Vassilis Rizopoulos. All rights reserved.

# frozen_string_literal: false

require 'ostruct'
require_relative 'parser'
require_relative 'reporter'
module Rutema
  ##
  # This module defines the configuration directives used for the configuration
  # of Rutema and test suites.
  #
  # A configuration file needs as a minimum to define which parser to use and
  # which tests to run.
  #
  # Since rutema configuration files are valid Ruby code, you can use the full
  # power of the Ruby language including require directives
  #
  # Example:
  #
  #     require 'rake'
  #     configure do |cfg|
  #       cfg.parser = { class: Rutema::Parsers::SpecificationParser }
  #       cfg.tests = ['../specs/T001.spec', '../specs/T002.spec']
  #     end
  module ConfigurationDirectives
    attr_reader :parser, :runner, :tools, :paths, :tests, :context, :setup, \
                :teardown, :suite_setup, :suite_teardown
    attr_accessor :reporters

    ##
    # Key-value pairs for passing data to the system.
    #
    # They are supposed to be used in the reporters and contain data such as
    # version numbers, tester names etc.
    #
    # If there is a key collision the last given value for a key wins.
    #
    # Example:
    #
    #     configure do |cfg|
    #       cfg.context = { key_a: 'A value' }
    #       cfg.context = { key_b: 'Another value' }
    #       cfg.context = { key_a: 'This value will override', key_c: 'One more value' }
    #     end
    def context=(definition)
      @context ||= {}
      raise ConfigurationException,
            'Only accepting hash values as context argument' unless definition.is_a?(Hash)

      @context.merge!(definition)
    end

    ##
    # A hash defining the parser to be utilized
    #
    # The hash is passed as is to the engine constructor and each parser
    # should define the necessary configuration keys.
    #
    # The only required key from the configurator's point of view is +:class+
    # which should be set to the fully qualified name of the class to use.
    #
    # Example:
    #
    #     configure do |cfg|
    #       { class: Rutema::Parsers::SpecificationParser }
    #     end
    def parser=(definition)
      raise ConfigurationException,
            "Required key :class is missing from #{definition} for parser" unless definition[:class]

      @parser = definition
    end

    ##
    # Add a path to the paths hash of the configuration
    #
    # Required keys:
    # * +:name+ - the name to use for accessing the path in code
    # * +:path+ - the path itself
    #
    # Example:
    #
    #     configure do |cfg|
    #       cfg.path = { name: 'doc', path: '/usr/share/doc' }
    #       cfg.path = { name: 'src', path: '/usr/src' }
    #     end
    def path=(definition)
      raise ConfigurationException,
            "Required key :name is missing from #{definition} of path" unless definition[:name]
      raise ConfigurationException,
            "Required key :path is missing from #{definition} of path" unless definition[:path]
      @paths[definition[:name]] = definition[:path]
    end

    ##
    # Add a reporter to the configuration.
    #
    # As with the parser, the only required configuration key is +:class+ and
    # the definition hash is passed to the class' constructor.
    #
    # Unlike the parser multiple reporters can be given.
    #
    # Example:
    #
    #     configure do |cfg|
    #       cfg.reporter = { class: Rutema::Reporters::BlockReporter }
    #       cfg.reporter = { class: Rutema::Reporters::EventReporter }
    #     end
    def reporter=(definition)
      raise ConfigurationException,
            "Required key :class is missing from #{definition} of reporter" unless definition[:class]

      @reporters[definition[:class]] = definition
    end

    ##
    # A hash defining the runner to be used by the engine
    #
    # The hash is passed as is to the runner constructor and each runner should
    # define the necessary configuration keys.
    #
    # The only required key from the configurator's point of view is +:class+
    # which should be set to the fully qualified name of the class to use.
    #
    # Example:
    #
    #     configure do |cfg|
    #       cfg.runner = { class: Rutema::Runners::Default }
    #     end
    def runner=(definition)
      raise ConfigurationException,
            "Required key :class is missing from #{definition} of runner" unless definition[:class]

      @runner = definition
    end

    ##
    # Path to a test case setup specification. (optional)
    #
    # This test case setup specification would be run before any test.
    #
    # Example:
    #
    #     configure do |cfg|
    #       cfg.setup = 'setup.spec'
    #     end
    def setup=(path)
      @setup = check_path(path)
    end

    ##
    # Path to a test suite setup specification. (optional)
    #
    # The suite setup test case runs once in the beginning of a test run before
    # all the tests of the suite.
    #
    # If it fails no tests are run.
    #
    # This is also aliased as check= for backwards compatibility.
    #
    # Example:
    #
    #     configure do |cfg|
    #       cfg.suite_setup = 'suite_setup.spec'
    #     end
    def suite_setup=(path)
      @suite_setup = check_path(path)
    end

    alias check suite_setup
    alias check= suite_setup=

    ##
    # Path to a test suite teardown specification. (optional)
    #
    # The suite teardown test runs after all the tests.
    #
    # Example:
    #
    #     configure do |cfg|
    #       cfg.suite_teardown = 'suite_teardown.spec'
    #     end
    def suite_teardown=(path)
      @suite_teardown = check_path(path)
    end

    ##
    # Path to the teardown specification. (optional)
    #
    # This test case teardown specification would be run after any test.
    #
    # Example:
    #
    #     configure do |cfg|
    #       cfg.teardown = 'teardown.spec'
    #     end
    def teardown=(path)
      @teardown = check_path(path)
    end

    ##
    # Add the specification identifiers for all test cases of this suite
    #
    # These will usually be files, but they also can be anything.
    # Essentially this is an array of strings that mean something to your parser
    #
    # Example:
    #
    #     configure do |cfg|
    #       cfg.tests = ['../specs/T001.spec', '../specs/T002.spec']
    #     end
    def tests=(array_of_identifiers)
      @tests += array_of_identifiers.map { |f| full_path(f) }
    end

    ##
    # Add a hash of values to the +tools+ hash of the configuration
    #
    # This hash is then accessible by the parser and the reporters as a
    # property of the configuration instance
    #
    # Required keys:
    # * +:name+ - the name to use for accessing the path in code
    #
    # Example:
    #
    #     configure do |cfg|
    #       cfg.tool = { name: 'cat', path: '/usr/bin/cat', configuration: {} }
    #       cfg.tool = { name: 'echo', path: '/usr/bin/echo', configuration: { param: '-n' } }
    #     end
    #
    # The path to +echo+ can then be accessed in the parser as
    #
    #     @configuration.tools.echo[:path]
    #
    # This way you can pass configuration information for the tools you use
    def tool=(definition)
      raise ConfigurationException,
            "Required key :name is missing from #{definition} of tool" unless definition[:name]

      @tools[definition[:name]] = definition
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
