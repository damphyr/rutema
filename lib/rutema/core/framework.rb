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
      @timestamp=params.fetch(:timestamp,0)
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
      msg="#{@test}:#{@number}"
      msg<<" #{@text}." unless @text.empty?
      outpt=output()
      msg<<" Output:\n#{outpt}" unless outpt.empty?
      return msg
    end

    def output
      msg=""
      msg<<"#{@out}\n" unless @out.empty?
      msg<<@err unless @err.empty?
      return msg
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