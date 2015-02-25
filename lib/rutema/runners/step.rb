#  Copyright (c) 2007-2011 Vassilis Rizopoulos. All rights reserved.
require_relative 'default'

module Rutema
  #StepRunner halts before every step and asks if it should be executed or not.
  class StepRunner<Runner
    def initialize setup=nil, teardown=nil,logger=nil
      @questioner=HighLine.new
      super(setup,teardown,logger)
    end
    def run_step step
      if @questioner.agree("Execute #{step.to_s}?")
        return super(step)
      else
        msg="#{step.number} - #{step.step_type} - #{step.status}"
        @logger.info(msg)
        return step
      end
    end
  end
end