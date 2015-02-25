#  Copyright (c) 2007-2010 Vassilis Rizopoulos. All rights reserved.
module Rutema
  #Rutema supports two kinds of reporters.
  #
  #Block reporters receive data via the report() method at the end of a Rutema run
  #while event reporters receive events continuously during a run via the update() method
  module Reporters
    class BlockReporter
      def initialize configuration,dispatcher
        @configuration=configuration
      end
      def report specifications,runner_states,parse_errors
      end
    end
    class EventReporter
      def initialize configuration,dispatcher
        @configuration=configuration
        @queue=dispatcher.subscribe(self.object_id)
      end

      def run! 
        @thread=Thread.new do
          while true do
            if  @queue.size>0
              data=@queue.pop
              update(data) if data
            end
            sleep 0.1
          end
        end
      end

      def update data
      end

      def exit
        if @thread
          while @queue.size>0 do
            sleep 0.1
          end
            Thread.kill(@thread)
          end
      end
    end
  end
end