# Copyright (c) 2007-2020 Vassilis Rizopoulos. All rights reserved.

# frozen_string_literal: true

require 'English'

require_relative 'parser'
require_relative 'reporter'
require_relative 'runner'

module Rutema
  ##
  # Rutema::Engine implements the rutema workflow
  #
  # It instantiates the configured parser and runner and reporter instances and
  # wires these together via Rutema::Dispatcher
  #
  # The full workflow is Parse->Run->Report and corresponds to one call of the
  # Engine#run method.
  class Engine
    include Messaging

    ##
    # Initialize new Rutema::Engine according to the passed
    # +configuration+
    #
    # This function creates a parser and a runner and a dispatcher which share
    # a common message queue.
    def initialize(configuration)
      @queue = Queue.new
      @parser = instantiate_class(configuration.parser, configuration) if configuration.parser
      if configuration.runner
        if configuration.runner[:class]
          @runner = configuration.runner[:class].new(configuration.context, @queue)
        else
          raise RutemaError, 'Runner setting overriden, but missing :class'
        end
      else
        @runner = Rutema::Runners::Default.new(configuration.context, @queue)
      end
      raise RutemaError, 'Could not instantiate parser' unless @parser

      @dispatcher = Dispatcher.new(@queue, configuration)
      @configuration = configuration
    end

    # Parse, run, report
    def run(test_identifier = nil)
      @dispatcher.run!
      # start
      message('start')
      suite_setup, suite_teardown, setup, teardown, tests = *parse(test_identifier)
      if tests.empty?
        @dispatcher.exit
        raise RutemaError, 'No tests to run!'
      else
        # running - at this point we've done any and all checks and we're stepping on the gas
        message('running')
        run_scenarios(tests, suite_setup, suite_teardown, setup, teardown)
      end
      message('end')
      @dispatcher.exit
      @dispatcher.report(tests)
    end

    # Parse a single test spec or all the specs listed in the configuration
    def parse(test_identifier = nil)
      specs = []
      # so, while we are parsing, we have a list of tests
      # we're either parsing all of the tests, or just one
      # make sure the one test is on the list
      if test_identifier
        if spec_included?(test_identifier)
          specs << parse_specification(File.expand_path(test_identifier))
        else
          error(File.expand_path(test_identifier), 'does not exist in the configuration')
        end
      else
        specs = parse_specifications(@configuration.tests)
      end
      specs.compact!
      suite_setup, suite_teardown, setup, teardown = parse_specials(@configuration)
      [suite_setup, suite_teardown, setup, teardown, specs]
    end

    private

    def parse_specifications(tests)
      tests.map do |t|
        parse_specification(t)
      end.compact
    end

    def parse_specification(spec_identifier)
      @parser.parse_specification(spec_identifier)
    rescue Rutema::ParserError
      error(spec_identifier, $ERROR_INFO.message)
      raise Rutema::ParserError, "In #{spec_identifier}: #{$ERROR_INFO.message}"
    end

    def parse_specials(configuration)
      suite_setup = nil
      suite_teardown = nil
      setup = nil
      teardown = nil
      suite_setup = parse_specification(configuration.suite_setup) if configuration.suite_setup
      suite_teardown = parse_specification(configuration.suite_teardown) if configuration.suite_teardown
      setup = parse_specification(configuration.setup) if configuration.setup
      teardown = parse_specification(configuration.teardown) if configuration.teardown
      [suite_setup, suite_teardown, setup, teardown]
    end

    ##
    #
    def run_scenarios(specs, suite_setup, suite_teardown, setup, teardown)
      if specs.empty?
        error(nil, 'No tests to run')
      else
        @runner.setup = nil
        @runner.teardown = nil

        if !suite_setup || (run_test(suite_setup, true) == :success)
          @runner.setup = setup
          @runner.teardown = teardown
          specs.each { |spec| run_test(spec) }
        else
          error(nil, 'Suite setup test failed')
        end
        if suite_teardown
          @runner.setup = nil
          @runner.teardown = nil
          run_test(suite_teardown, true)
        end
      end
    end

    ##
    # Run a particular test +specification+ or don't execute it if not
    #
    # +is_special+ conveys if the +specification+ is a setup or teardown one.
    def run_test(specification, is_special = false)
      if specification.scenario
        status = @runner.run(specification, is_special)['status']
      else
        status = :not_executed
        message(status: status, test: specification.name, text: 'No scenario')
      end
      status
    end

    ##
    # Instantiate a new instance of the class defined by the +:class+ key within
    # +definition+ and pass the +configuration+ to its constructor
    def instantiate_class(definition, configuration)
      if definition[:class]
        klass = definition[:class]
        return klass.new(configuration)
      end
      nil
    end

    ##
    # Check if the +test_identifier+ specification is either part of the tests
    # or the setup and teardown specifications
    def spec_included?(test_identifier)
      full_path = File.expand_path(test_identifier)
      @configuration.tests.include?(full_path) || special?(test_identifier)
    end

    ##
    # Check if the expanded full path of +test_identifier+ matches any of the
    # configured setup or teardown specifications
    def special?(test_identifier)
      full_path = File.expand_path(test_identifier)
      [@configuration.suite_setup, @configuration.suite_teardown,
       @configuration.setup, @configuration.teardown].include?(full_path)
    end
  end
end
