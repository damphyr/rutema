# Copyright (c) 2007-2020 Vassilis Rizopoulos. All rights reserved.

module Rutema
  ##
  # Rutema::Message is the base class of different message types for exchanging data
  #
  # The two classes Rutema::ErrorMessage and Rutema::RunnerMessage are the
  # primarily used message classes throughout Rutema.
  class Message
    ##
    # Test id or name of the respective test
    attr_accessor :test
    ##
    # Message text
    attr_accessor :text
    ##
    # A timestamp respective to the message
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
      msg << "#{@test} " unless @test.empty?
      msg << @text
    end
  end
  #What it says on the tin.
  class ErrorMessage<Message
    def to_s
      msg="ERROR - "
      msg<<"#{@test} " unless @test.empty?
      msg<<@text
      return msg
    end
  end
  #The Runner continuously sends these when executing tests
  #
  #If there is an engine error (e.g. when parsing) you will get an ErrorMessage, if it is a test error
  #you will get a RunnerMessage with :error in the status.
  class RunnerMessage<Message
    attr_accessor :duration,:status,:number,:out,:err
    def initialize params
      super(params)
      @duration=params.fetch("duration",0)
      @status=params.fetch("status",:none)
      @number=params.fetch("number",1)
      @out=params.fetch("out","")
      @err=params.fetch("err","")
    end

    def to_s
      msg="#{@test}:"
      msg<<"#{@text}." unless @text.empty?
      outpt=output()
      msg<<" Output:\n#{outpt}" unless outpt.empty? || @status!=:error
      return msg
    end

    def output
      msg=""
      msg<<"#{@out}\n" unless @out.empty?
      msg<<@err unless @err.empty?
      return msg.chomp
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
  # to the status of the most recently inserted message.
  class ReportTestState
    ##
    # Holds all inserted Rutema::RunnerMessage instances
    attr_accessor :steps
    ##
    # Accumulates the durations of all inserted messages
    attr_reader :duration
    ##
    # Always has the status of the most recently inserted message
    attr_reader :status
    ##
    # The name of the respective test whose messages this Rutema::ReportTestState collects
    attr_reader :test
    ##
    # The timestamp of the first message of the test
    attr_reader :timestamp

    ##
    # Create a new Rutema::ReportTestState instance from a Rutema::RunnerMessage
    def initialize(message)
      @duration = message.duration
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

      @duration += message.duration
      @status = message.status
      @steps << message
    end
  end

  ##
  # Module offering convenience methods for creating error and normal messages
  #
  # The only requirement for including classes is that an @queue instance
  # variable exists where the created messages can be pushed to.
  #
  # Messages pushed through these convenience functions will have their
  # timestamp set to the moment of their creation.
  module Messaging
    ##
    # Push a new Rutema::ErrorMessage to the queue
    #
    # +identifier+ will be used for the test name and +message+ for the text.
    def error identifier,message
      @queue.push(ErrorMessage.new(:test=>identifier,:text=>message,:timestamp=>Time.now))
    end

    ##
    # Push a new Rutema::Message or Rutema::RunnerMessage to the queue
    #
    # +message+ can either be a String or a Hash instance. In case of a String
    # the test name attribute will be unset and the +message+ will become the
    # text of the Rutema::Message instance.
    #
    # If +message+ is an instance of Hash the created message will be
    # initialized from it. If the Hash contains a 'status' key a
    # Rutema::RunnerMessage will be created, otherwise a Rutema::Message
    def message message
      case message
      when String
        Message.new(:text=>message,:timestamp=>Time.now)
      when Hash
        hm=Message.new(message)
        hm=RunnerMessage.new(message) if message[:test] && message["status"]
        hm.timestamp=Time.now
        @queue.push(hm)
      end
    end
  end
  #Generic error class for errors in the engine
  class RutemaError<RuntimeError
  end
  #Is raised when an error is found in a specification
  class ParserError<RutemaError
  end
  #Is raised on an unexpected error during execution
  class RunnerError<RutemaError
  end
  #Errors in reporters should use this class
  class ReportError<RutemaError
  end
end
