module Rutema
  module Messaging
    def error identifier,message
      message(:test=>identifier,:error=>message)
    end
    def message message
      msg=message
      if message.is_a?(String)
        msg={:message=>message,:timestamp=>Time.now}
      elsif message.is_a?(Hash)
        msg[:timestamp]=Time.now
      end
      @queue.push(msg)
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