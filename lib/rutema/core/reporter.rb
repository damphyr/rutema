# Copyright (c) 2007-2020 Vassilis Rizopoulos. All rights reserved.

require 'English'

module Rutema
  #Rutema supports two kinds of reporters.
  #
  #Block (from en bloc) reporters receive data via the report() method at the end of a Rutema run
  #while event reporters receive events continuously during a run via the update() method
  #
  #Nothing prevents you from creating a class that implements both behaviours
  module Reporters
    ##
    # An empty base class for all reporter classes
    class BaseReporter
    end

    ##
    # A Rutema::Reporters::BlockReporter receives its data once at the end of a
    # _rutema_ run
    class BlockReporter < BaseReporter
      ##
      # Initialize a new Rutema::Reporters::BlockReporter instance
      #
      # The +configuration+ argument is stored internally for later usage.
      # +dispatcher+ is unused.
      def initialize(configuration, _dispatcher)
        @configuration = configuration
      end

      ##
      # Conduct (e.g. write to a file or _stdout_) a report based on the passed
      # data
      def report(specifications, states, errors) end
    end

    ##
    # A Rutema::Reporters::EventReporter receives its data continually during a
    # _rutema_ run
    class EventReporter < BaseReporter
      ##
      # Initialize a new Rutema::Reporters::EventReporter instance
      #
      # The +configuration+ argument is stored internally for later usage.
      # The passed +dispatcher+ is being subscribed to.
      def initialize(configuration, dispatcher)
        @configuration = configuration
        @queue = dispatcher.subscribe(object_id)
      end

      ##
      # Start a new Thread which regularly (each 0.1 seconds) calls #update for
      # all data received through the dispatcher which was given on initialization
      def run!
        @thread = Thread.new do
          loop do
            data = @queue.pop
            begin
              update(data) if data
            rescue
              puts "#{self.class} failed with #{$ERROR_INFO.message}"
              raise
            end
          end
        end
      end

      ##
      # Update the Rutema::Reporters::EventReporter with some data
      #
      # In the currently existing implementations the derived reporters expect
      # class instances derived from Rutema::Message as data.
      def update(data) end

      ##
      # This blocks as long as the thread is alive and messages are still in the
      # queue.
      #
      # If one of the two conditions becomes +false+ the thread is killed and
      # the method returns.
      def exit
        puts "Exiting #{self.class}" if $DEBUG

        return unless @thread

        puts "Reporter died with #{@queue.size} messages in the queue" unless @thread.alive?
        sleep 0.1 while !@queue.empty? && @thread.alive?
        Thread.kill(@thread)
      end
    end

    ##
    # This reporter is always instantiated (within Rutema::Dispatcher within
    # Rutema::Engine) and collects all messages fired by the _rutema_ engine
    #
    # The collections of errors and states are then at the end of a run fed to
    # the block reporters.
    class Collector < EventReporter
      attr_reader :errors, :states

      ##
      # Initialize a new instance and create publicly accessible #errors Array and #states Hash
      def initialize(params, dispatcher)
        super(params, dispatcher)
        @errors = []
        @states = {}
      end

      ##
      # Update the internal state of the class depending on the given +message+
      #
      # Only messages instances of type Rutema::ErrorMessage or
      # Rutema::RunnerMessage have an effect.
      #
      # Rutema::ErrorMessage instances are accumulated in the #errors Array.
      #
      # Rutema::RunnerMessage instances of each individual test are accumulated
      # in a respective Rutema::ReportTestState instance.
      def update(message)
        case message
        when RunnerMessage
          test_state = @states[message.test]
          if test_state
            test_state << message
          else
            test_state = Rutema::ReportTestState.new(message)
          end
          @states[message.test] = test_state
        when ErrorMessage
          @errors << message
        end
      end
    end

    ##
    # A very simple event reporter that outputs to the console (i.e. +stdout+)
    #
    # It has three available modes:
    # * +off+
    # * +normal+
    # * +verbose+
    #
    # In mode +off+ it does not output anything to the console. In mode +normal+
    # it outputs Rutema::ErrorMessage instances and Rutema::RunnerMessage
    # instances whose +status+ is +:error+. In mode +verbose+ all messages are
    # output to the console.
    #
    # Example:
    #
    #     configure do |cfg|
    #       cfg.reporter={ class: Rutema::Reporters::Console, 'mode' => 'verbose' }
    #     end
    class Console < EventReporter
      ##
      # Initialize by the given configuration and subscribe to the given dispatcher
      def initialize(configuration, dispatcher)
        super(configuration, dispatcher)
        @mode = configuration.reporters.fetch(self.class, {})['mode']
      end

      ##
      # Output the given +message+ to console according to the configured +mode+
      def update(message)
        return if @mode == 'off'

        case message
        when RunnerMessage
          if message.status == :error
            puts "FATAL|#{message}"
          elsif message.status == :warning
            puts "WARNING|#{message}"
          elsif @mode == 'verbose'
            puts "#{message} #{message.status}."
          end
        when ErrorMessage
          puts message.to_s
        when Message
          puts message.to_s if @mode == 'verbose'
        end
      end
    end

    class Summary<BlockReporter
      def initialize configuration,dispatcher
        super(configuration,dispatcher)
        @silent=configuration.reporters.fetch(self.class,{})["silent"]
      end
      def report specs,states,errors
        failures=[]
        states.each{|k,v| failures<<v.test if v.status==:error}

        unless @silent
          count_tests_run = states.select { |name, state| !state.is_special }.count
          puts "#{errors.size} errors. #{count_tests_run} test cases executed. #{failures.size} failed"
          unless failures.empty?
            puts "Failures:"
            puts specs.map{|spec| "  #{spec.name} - #{spec.filename}" if failures.include?(spec.name)}.compact.join("\n")
          end
        end
        return failures.size+errors.size
      end
    end
  end

  ##
  # The Rutema::Utilities module is intended for the accumulation of methods
  # useful in multiple contexts
  module Utilities
    require "fileutils"

    ##
    # Write +content+ to a file at the location +filename+
    #
    # The file and the directories containing it are being created if they don't
    # exist yet. If the file already exists it is being truncated.
    def self.write_file filename,content
      FileUtils.mkdir_p(File.dirname(filename),:verbose=>false)
      File.open(filename, 'wb') {|f| f.write(content) }
    end  
  end
end
