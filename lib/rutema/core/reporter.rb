#  Copyright (c) 2007-2021 Vassilis Rizopoulos. All rights reserved.

module Rutema
  ##
  # Module for the definition of reporter classes
  #
  # rutema supports two kinds of reporters. Reporters derived from BlockReporter
  # are supposed to receive data via the #report method at the end of a Rutema
  # run. Reporters derived from EventReporter are intended to receive events
  # continuously during a run via the #update method.
  #
  # Nothing permits implementing a reporter class which supports both
  # behaviours.
  module Reporters
    ##
    # Base class for block reporters
    #
    # Block reporters are invoked at the end/after a test run. They offer means
    # to e.g. print a summary after a test run or create a test report file for
    # CI integration (see Reporters::JUnit as an example).
    class BlockReporter
      ##
      # Initialize a new instance from the given configuration
      #
      # * +configuration+ - the Configuration instance of the test run
      # * +dispatcher+ - unused
      def initialize(configuration, _dispatcher)
        @configuration = configuration
      end

      ##
      #
      def report(specifications, states, errors)
      end
    end

    ##
    # Event reporters receive and process information continually during a test
    # run
    class EventReporter
      def initialize(configuration, dispatcher)
        @configuration = configuration
        @queue = dispatcher.subscribe(object_id)
      end

      def run!
        @thread = Thread.new do
          loop do
            data = @queue.pop
            begin
              update(data) if data
            rescue StandardError
              puts "#{self.class} failed with #{$!.message}"
              raise
            end
          end
        end
      end

      def update(data)
      end

      def exit
        puts "Exiting #{self.class}" if $DEBUG
        return unless @thread

        puts "Reporter died with #{@queue.size} messages in the queue" unless @thread.alive?
        sleep 0.1 while !@queue.empty? && @thread.alive?
        Thread.kill(@thread)
      end
    end

    # This reporter is always instantiated and collects all messages fired by the rutema engine
    #
    # The collections of errors and states are then at the end of a run fed to the block reporters
    class Collector < EventReporter
      attr_reader :errors, :states

      def initialize(params, dispatcher)
        super
        @errors = []
        @states = {}
      end

      def update(message)
        case message
        when RunnerMessage
          test_state = @states[message.test]
          if test_state
            test_state << message
          else
            test_state = Rutema::ReportState.new(message)
          end
          @states[message.test] = test_state
        when ErrorMessage
          @errors << message
        end
      end
    end

    # A very simple event reporter that outputs to the console
    #
    # It has three settings: off, normal and verbose.
    #
    # Example configuration:
    # cfg.reporter={:class=>Rutema::Reporters::Console, "mode"=>"verbose"}
    class Console < EventReporter
      def initialize(configuration, dispatcher)
        super
        @mode = configuration.reporters.fetch(self.class, {})["mode"]
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def update(message)
        return if @mode == "off"

        case message
        when RunnerMessage
          if message.status == :error
            puts "FATAL|#{message}"
          elsif message.status == :warning
            puts "WARNING|#{message}"
          elsif @mode == "verbose"
            puts "#{message} #{message.status}."
          end
        when ErrorMessage
          puts message
        when Message
          puts message if @mode == "verbose"
        end
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    # Produces a summary of the test run returning aggregate numbers for tests and failures
    class Summary < BlockReporter
      def initialize(configuration, dispatcher)
        super
        @silent = configuration.reporters.fetch(self.class, {})["silent"]
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def report(specs, states, errors)
        failures = []
        states.each_value { |v| failures << v.test if v.status == :error }

        unless @silent
          count_tests_run = states.reject { |_name, state| state.is_special }.count
          puts "#{errors.size} errors. #{count_tests_run} test cases executed. #{failures.size} failed"
          unless failures.empty?
            puts "Failures:"
            puts specs.map { |spec| "  #{spec.name} - #{spec.filename}" if failures.include?(spec.name) }.compact.join("\n")
          end
        end
        return failures.size + errors.size
      end
      # rubocop:enable Metrics/CyclomaticComplexity
    end
  end

  # rubocop:disable Style/Documentation
  module Utilities
    require "fileutils"
    def self.write_file(filename, content)
      FileUtils.mkdir_p(File.dirname(filename), :verbose => false)
      File.binwrite(filename, content)
    end
  end
  # rubocop:enable Style/Documentation
end
