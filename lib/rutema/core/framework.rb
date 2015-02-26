module Rutema
  module Messaging
    def error identifier,message
      message(:test=>identifier,:error=>message,:timestamp=>Time.now)
    end
    def message message
      msg=message
      if message.is_a?(String)
        msg={:message=>message,:timestamp=>Time.now}
      end
      @queue.push(msg)
    end
  end
  #Is raised when an error is found in a specification
  class ParserError<RuntimeError
  end
  #Is raised on an unexpected error during execution
  class RunnerError<RuntimeError
  end
  #Errors in reporters should use this class
  class ReportError<RuntimeError
  end
end