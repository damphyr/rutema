#  Copyright (c) 2021 Vassilis Rizopoulos. All rights reserved.

module Rutema
  STATUS_CODES=[:started,:skipped,:success,:warning,:error]

  ##
  # Simple base for classes concerned with message passing to report test
  # progress and failures
  #
  # This class and its descendants can be utilized as a container for data
  # relevant to tests and their results. Currently they are being emitted by the
  # Engine and Runners instances and consumed by classes within the  Reporters
  # module.
  #
  # Specialized descendants are ErrorMessage and RunnerMessage.
  class Message
    ##
    # The test whose execution originated the message
    attr_accessor :test
    ##
    # The text of the message
    attr_accessor :text
    ##
    # The timestamp of the message's creation
    attr_accessor :timestamp

    ##
    # Initialize a new message from data passed in a hash
    #
    # The following keys of the hash are being utilized:
    # * +:test+ - the test id/name of the test which originates the message
    # * +:text+ - the text of the message
    # * +:timestamp+ - most often the timestamp of the creation of the message,
    #   defaults to +Time.now+
    def initialize params
      @test=params.fetch(:test,"")
      @test||=""
      @text=params.fetch(:text,"")
      @timestamp=params.fetch(:timestamp,Time.now)
    end

    ##
    # Convert the instance to a convenient textual representation
    def to_s
      msg=""
      msg<<"#{@test} " unless @test.empty?
      msg<<@text
      return msg
    end
  end

  ##
  # Message container to report test errors
  #
  # The reported on errors may concern the test specifications, parser errors or
  # errors which occurred during test execution. Logic errors of rutema itself
  # are not reported by means of this class.
  class ErrorMessage<Message
    ##
    # Convert the instance to a convenient textual representation
    def to_s
      msg="ERROR - "
      msg<<"#{@test} " unless @test.empty?
      msg<<@text
      return msg
    end
  end

  ##
  # Message container continually being emitted by runners (see Runners module)
  # during test execution
  #
  # These messages inform about the progress of test execution. Test errors are
  # propagated through instances of this class as well. If it's an engine error
  # (e.g. during parsing), then an ErrorMessage will be used in that case.
  class RunnerMessage<Message
    attr_accessor :duration, :status, :number, :out, :err, :is_special

    ##
    # Initialize a new runner message from data passed in a hash
    #
    # Additionally to the keys of the Message initializer the following keys of
    # the hash are being utilized:
    # * "duration" - the time a test step took for execution
    # * "status" - the status of the respective step
    # * +:timestamp+ - most often the timestamp of the creation of the message,
    #   defaults to +Time.now+
    def initialize params
      super(params)
      @duration=params.fetch("duration",0)
      @status=params.fetch("status",:none)
      @number=params.fetch("number",1)
      @out=params.fetch("out","")
      @err=params.fetch("err","")
      @backtrace=params.fetch("backtrace","")
      @is_special=params.fetch("is_special","")
    end

    ##
    # Convert the instance to a convenient textual representation
    def to_s
      msg="#{@test}:"
      msg<<" #{@timestamp.strftime("%H:%M:%S")} :"
      msg<<"#{@text}." unless @text.empty?
      outpt=output()
      msg<<" Output" + (outpt.empty? ? "." : ":\n#{outpt}") # unless outpt.empty? || @status!=:error
      return msg
    end

    def output
      msg=""
      msg<<"#{@out}\n" unless @out.empty?
      msg<<@err unless @err.empty?
      msg<<"\n" + (@backtrace.kind_of?(Array) ? @backtrace.join("\n") : @backtrace) unless @backtrace.empty?
      return msg.chomp
    end
  end

  #While executing tests the state of each test is collected in an 
  #instance of ReportState and the collection is at the end passed to the available block reporters
  #
  #ReportState assumes the timestamp of the first message, the status of the last message
  #and accumulates the duration reported by all messages in it's collection.
  class ReportState
    attr_accessor :steps
    attr_reader :test, :timestamp, :duration, :status, :is_special
    
    def initialize message
      @test=message.test
      @timestamp=message.timestamp
      @duration=message.duration
      @status=message.status
      @steps=[message]
      @is_special=message.is_special
    end

    def <<(message)
      @steps<<message
      @duration+=message.duration
      @status = message.status unless message.status.nil? \
        || (!@status.nil? && STATUS_CODES.find_index(message.status) < STATUS_CODES.find_index(@status))
    end
  end

  ##
  # Mix-in module which offers an interface to push messages to a queue
  #
  # Instances of the class including this module need a @queue member variable.
  module Messaging
    ##
    # Push a new ErrorMessage instance to the queue
    #
    # * +identifier+ - in most cases this would be the name of a test or its
    #   specification file
    # * +message+ - a short descriptive message detailing the error condition
    def error identifier,message
      @queue.push(ErrorMessage.new(:test=>identifier,:text=>message,:timestamp=>Time.now))
    end

    ##
    # Push a new Message or RunnerMessage instance to the queue
    #
    # If +message+ is of type String a Message instance will be pushed to the
    # queue. If it's of type Hash it will be passed to the initializer of
    # RunnerMessage if it has both the keys :test and "status" or to the
    # initializer of Message if not so.
    def message message
      case message
      when String
        @queue.push(Message.new(:text=>message,:timestamp=>Time.now))
      when Hash
        hm=Message.new(message)
        hm=RunnerMessage.new(message) if message[:test] && message["status"]
        hm.timestamp=Time.now
        @queue.push(hm)
      end
    end
  end

  ##
  # Generic error class which is being used as base class for all other rutema
  # errors and for Engine related errors.
  #
  # This is being inherited by:
  # * ParserError
  # * ReportError
  # * RunnerError
  class RutemaError<RuntimeError
  end

  ##
  # Specialized error class particular to the parsing of rutema test
  # specifications
  class ParserError < RutemaError
  end

  ##
  # Specialized error class designated to errors within runner classes
  class RunnerError < RutemaError
  end

  ##
  # Specialized error class which should be utilized by Reporters members to
  # signal errors upon reporting
  class ReportError < RutemaError
  end
end
