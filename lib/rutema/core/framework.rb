# Copyright (c) 2007-2020 Vassilis Rizopoulos. All rights reserved.

# frozen_string_literal: false

module Rutema
  ##
  # A list of possible states a Rutema::RunnerMessage can transport
  STATUS_CODES = %i[uninitialized skipped success warning error].freeze
  ##
  # Rutema::Message is the base class of different message types for exchanging data
  #
  # The two classes Rutema::ErrorMessage and Rutema::RunnerMessage are the
  # primarily used message classes throughout Rutema.
  #
  # Messages are mostly created by Rutema::Engine and Rutema::Runners class
  # instances through the Rutema::Messaging module. Errors within Rutema will be
  # represented by Rutema::ErrorMessage instances. Test errors are represented
  # by Rutema::RunnerMessage instances which have their +status+ attribute set
  # to +:error+.
  class Message
    ##
    # Test id or name of the respective test
    attr_accessor :test
    ##
    # Message text
    attr_accessor :text
    ##
    # A timestamp respective to the message (in all known cases the time of
    # message creation)
    attr_accessor :timestamp

    ##
    # Initialize a new message from a Hash
    #
    # The following keys of the hash are used:
    # * +test+ - the test id/name (defaults to an empty string)
    # * +text+ - the text of the message (defaults to an empty string)
    # * +timestamp+ - a timestamp (defaults to +Time.now+)
    def initialize(params)
      @test = params.fetch(:test, '')
      @text = params.fetch(:text, '')
      @timestamp = params.fetch(:timestamp, Time.now)
    end

    ##
    # Convert the message to a string representation
    def to_s
      msg = ''
      msg << "#{@test}: " unless @test.empty?
      msg << @text
    end
  end

  ##
  # Rutema::ErrorMessage is a class for simple error messages
  #
  # Compared to Rutema::Message it does not contain any additional information.
  # The only difference is that "Error - " is being prepended to its stringified
  # representation.
  #
  # This class is mainly used to signal errors concerning the execution of
  # Rutema. Test errors are signalled by Rutema::RunnerMessage instances with
  # the +status+ attribute set to +:error+.
  class ErrorMessage < Message
    ##
    # Convert the message to a string representation
    def to_s
      'ERROR - ' + super
    end
  end

  ##
  # Rutema::RunnerMessage instances are repeatedly created during test execution
  #
  # These messages are particular to a respective test and carry additional
  # information compared to the base Rutema::Message
  class RunnerMessage < Message
    ##
    # The backtrace of a conducted but failed step
    attr_accessor :backtrace
    ##
    # The duration of a test step
    attr_accessor :duration
    ##
    # An error occurred during a step or a test
    attr_accessor :err
    ##
    # The represented step is a special one (i.e. a setup or teardown step)
    attr_accessor :is_special
    ##
    # The number of a test step
    attr_accessor :number
    ##
    # The output of a test step
    attr_accessor :out
    ##
    # The status of a respective test step or test itself
    attr_accessor :status

    ##
    # Initialize a new Rutema::RunnerMessage from a Hash
    #
    # The following (additional to Rutema::Message) keys of the hash are used:
    # * 'backtrace' - A backtrace of a conducted but failed step (defaults to an
    #   empty string)
    # * 'duration' - An optional duration of a step (defaults to +0+)
    # * 'err' - An optional error message (defaults to an empty string)
    # * 'is_special' - If the respective step is a special one (i.e. setup or
    #   teardown - defaults to +false+)
    # * 'number' - The number of a step (defaults to +1+)
    # * 'out' - An optional output of a step (defaults to an empty string)
    # * 'status' - A status of a step or the respective test (defaults to +:uninitialized+)
    def initialize(params)
      super(params)

      @backtrace = params.fetch('backtrace', '')
      @duration = params.fetch('duration', 0)
      @err = params.fetch('err', '')
      @is_special = params.fetch('is_special', false)
      @number = params.fetch('number', 1)
      @out = params.fetch('out', '')
      @status = params.fetch('status', :uninitialized)
    end

    ##
    # Convert the message to a string representation
    #
    # The output of the #output method will be appended, if this returns a non-
    # empty string
    def to_s
      msg = "#{@test}:"
      msg << " #{@timestamp.strftime('%H:%M:%S')} :"
      msg << "#{@text}." unless @text.empty?
      outpt = output
      msg << "\n#{outpt}" unless outpt.empty?
      msg
    end

    ##
    # Return a string combining the stored step output, error string and
    # backtrace
    def output
      msg = ''
      msg << "Output: \"#{@out}\"\n" unless @out.empty?
      msg << "Error: \"#{@err}\"\n" unless @err.empty?
      msg << "Backtrace:\n" + (@backtrace.is_a?(Array) ? @backtrace.join("\n") : @backtrace) unless @backtrace.empty?
      msg.chomp
    end
  end

  ##
  # Rutema::ReportTestState is used by the Rutema::Reporters::Collector event
  # reporter to accumulate all Rutema::RunnerMessage instances emitted by a
  # specific test. This accumulated data can then in the end be passed to block
  # reporters.
  #
  # Rutema::ReportTestState permanently assumes the name of the respective test
  # in its +test+ attribute and the timestamp of the first received message in
  # its +timestamp+ attribute.
  #
  # Durations will be accumulated in the +duration+ attribute and all inserted
  # messages in the +steps+ attribute. The +status+ attribute will always be set
  # to the status of the highest priority of all the inserted messages. The
  # order of the status priorities can be seen in ascending order in
  # STATUS_CODES in the Rutema module
  class ReportTestState
    ##
    # Accumulates the durations of all inserted messages
    attr_reader :duration
    ##
    # If the Rutema::Message passed on initialization was a special one
    attr_reader :is_special
    ##
    # Always has highest priority status of all inserted messages
    attr_reader :status
    ##
    # Holds all inserted Rutema::RunnerMessage instances
    attr_accessor :steps
    ##
    # The name of the respective test whose messages this
    # Rutema::ReportTestState collects
    attr_reader :test
    ##
    # The timestamp of the first message of the test
    attr_reader :timestamp

    ##
    # Create a new Rutema::ReportTestState instance from a Rutema::RunnerMessage
    def initialize(message)
      @duration = message.duration
      @is_special = message.is_special
      @status = message.status
      @steps = [message]
      @test = message.test
      @timestamp = message.timestamp
    end

    ##
    # Accumulate a further Rutema::RunnerMessage instance
    #
    # Throws a Rutema::RunnerError if a message of a different test is being
    # inserted than what the Rutema::ReportTestState instance was created with.
    def <<(message)
      if message.test != @test
        raise Rutema::RunnerError,
              "Attempted to insert \"#{message.test}\" message into \"#{@test}\" ReportTestStates"
      end

      append_message_and_update(message)
    end

    private

    ##
    # Add message to the steps Array and update duration and status attributes
    def append_message_and_update(message)
      @duration += message.duration
      unless message.status.nil? \
        || (!@status.nil? && STATUS_CODES.find_index(message.status) \
            < STATUS_CODES.find_index(@status))
        @status = message.status
      end
      @steps << message
    end
  end

  ##
  # Module offering convenience methods for creating error and normal messages
  #
  # The only requirement for including classes is that a @queue instance
  # variable exists where the created messages can be pushed to.
  #
  # Messages pushed through these convenience functions will have their
  # timestamp set to the moment of their creation.
  module Messaging
    ##
    # Push a new Rutema::ErrorMessage to the queue
    #
    # +identifier+ will be used for the test name and +message+ for the text.
    def error(identifier, message)
      @queue.push(ErrorMessage.new(test: identifier, text: message))
    end

    ##
    # Push a new Rutema::Message or Rutema::RunnerMessage to the queue
    #
    # +message+ can either be a String or a Hash instance. In case of a String
    # the test name attribute will be unset and the +message+ will become the
    # text of the Rutema::Message instance.
    #
    # If +message+ is an instance of Hash the created message will be
    # initialized from it. If the Hash contains a 'status' and a +:test+ key a
    # Rutema::RunnerMessage will be created, otherwise a Rutema::Message
    def message(message)
      hm = case message
           when String
             Message.new(text: message)
           when Hash
             if message[:test] && message['status']
               RunnerMessage.new(message)
             else Message.new(message)
             end
           end
      @queue.push(hm) if hm.is_a?(Message)
    end
  end
end
