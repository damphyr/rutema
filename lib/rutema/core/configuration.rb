# Copyright (c) 2007-2020 Vassilis Rizopoulos. All rights reserved.

# frozen_string_literal: false

require 'English'
require 'ostruct'

require_relative 'parser'
require_relative 'reporter'

module Rutema
  ##
  # This module defines the configuration directives used for the configuration
  # of Rutema and the test suites to be run with it.
  #
  # A configuration file needs as a minimum to define which parser to use and
  # which tests to run.
  #
  # Since rutema configuration files are valid Ruby code you can use the full
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
      unless definition.is_a?(Hash)
        raise ConfigurationException,
              'Only accepting hash values as context argument'
      end

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
    #       cfg.parser = { class: Rutema::Parsers::XML }
    #     end
    def parser=(definition)
      unless definition[:class]
        raise ConfigurationException,
              "Required key :class is missing from #{definition} for parser"
      end

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
      unless definition[:name]
        raise ConfigurationException,
              "Required key :name is missing from #{definition} of path"
      end
      unless definition[:path]
        raise ConfigurationException,
              "Required key :path is missing from #{definition} of path"
      end
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
      unless definition[:class]
        raise ConfigurationException,
              "Required key :class is missing from #{definition} of reporter"
      end

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
      unless definition[:class]
        raise ConfigurationException,
              "Required key :class is missing from #{definition} of runner"
      end

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
      @tests += array_of_identifiers.map { |f| full_path_or_filename(f) }
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
      unless definition[:name]
        raise ConfigurationException,
              "Required key :name is missing from #{definition} of tool"
      end

      @tools[definition[:name]] = definition
    end

    ##
    # Initialize mandatory local variables
    def init
      @context = {}
      @paths = OpenStruct.new
      @reporters = {}
      @tests = []
      @tools = OpenStruct.new
    end

    private

    ##
    # Check if a path exists and raise a ConfigurationException if it does not
    def check_path(path)
      path = File.expand_path(path)
      raise ConfigurationException, "#{path} does not exist" unless File.exist?(path)

      path
    end

    ##
    # Return a string of key=value,key=value for a hash
    def definition_string(definition)
      msg = []
      definition.each { |k, v| msg << "#{k}=#{v}" }
      msg.join(',')
    end

    def full_path_or_filename(filename)
      return File.expand_path(filename) if File.exist?(filename)

      filename
    end
  end

  ##
  # An exception that is being raised on errors processing a _rutema_ configuration
  class ConfigurationException < RuntimeError
  end

  ##
  # Class for loading configuration files and storing and manipulating configuration options
  #
  # All relevant local variables and methods are in Rutema::ConfigurationDirectives
  class Configuration
    include ConfigurationDirectives
    attr_reader :filename

    ##
    # Load the passed configuration file and initialize from contained configuration
    def initialize(config_file)
      @filename = config_file
      init
      load_configuration(@filename)
    end

    ##
    # Pass a block with configuration directives to modify the instance
    #
    # If no block is given this does nothing.
    #
    # Example:
    #
    #     cfg.configure { |conf| conf.context = { key_a: 'A value' } }
    def configure
      return unless block_given?

      yield self
    end

    ##
    # Load additional configuration from another file
    #
    # This can be used to accumulate information from multiple configuration
    # files. If the options from the second file accumulate with or replace
    # existing options from previous files can be checked through the respective
    # Rutema::ConfigurationDirectives method explanations.
    #
    # Example:
    #
    # General configuration directives could be stored in a file
    # +base_config.rutema+ and further test suite specific information in
    # +test_suite_a.rutema+. They could be combined in the following way:
    #
    #     cfg = Rutema::Configuration.new('base_config.rutema')
    #     cfg.import('test_suite_a.rutema')
    def import(filename)
      fnm = File.expand_path(filename)
      raise ConfigurationException, "Import error: Can't find #{fnm}" unless File.exist?(fnm)

      load_configuration(fnm)
    end

    private

    def load_configuration(filename)
      cfg_txt = File.read(filename)
      cwd = File.expand_path(File.dirname(filename))
      # WORKAROUND for ruby 2.3.1
      fname = File.basename(filename)
      # evaluate in the working directory to enable relative paths in configuration
      Dir.chdir(cwd) { eval(cfg_txt, binding(), fname, __LINE__) }
    rescue ConfigurationException
      # pass it on, do not wrap again
      raise
    rescue SyntaxError
      # Just wrap the exception so we can differentiate
      raise ConfigurationException.new, "Syntax error in the configuration file '#{filename}':\n#{$ERROR_INFO.message}"
    rescue NoMethodError
      raise ConfigurationException.new, \
            "Encountered an unknown directive in configuration file '#{filename}':\n#{$ERROR_INFO.message}"
    rescue
      # Just wrap the exception so we can differentiate
      raise ConfigurationException.new, $ERROR_INFO.message.to_s
    end
  end
end
