module Rutema
  #Represents the data beeing shunted between the components in lieu of logging.
  #
  #This is the primary type passed to the event reporters
  class Message
    attr_accessor :test,:text,:timestamp
    #Keys used:
    # test - the test id/name
    # text - the text of the message
    # timestamp
    def initialize params
      @test=params.fetch(:test,"")
      @text=params.fetch(:text,"")
      @timestamp=params.fetch(:timestamp,Time.now)
    end

    def to_s
      msg=""
      msg<<"#{@test} " unless @test.empty?
      msg<<@text
      return msg
    end
  end

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

  #While executing tests the state of each test is collected in an 
  #instance of ReportState and the collection is at the end passed to the available block reporters
  #
  #ReportState assumes the timestamp of the first message, the status of the last message
  #and accumulates the duration reported by all messages in it's collection.
  class ReportState
    attr_accessor :steps
    attr_reader :test,:timestamp,:duration,:status
    
    def initialize message
      @test=message.test
      @timestamp=message.timestamp
      @duration=message.duration
      @status=message.status
      @steps=[message]
    end

    def <<(message)
      @steps<<message
      @duration+=message.duration
      @status=message.status
    end
  end

  module Messaging
    def error identifier,message
      @queue.push(ErrorMessage.new(:test=>identifier,:text=>message,:timestamp=>Time.now))
    end
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