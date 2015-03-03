#  Copyright (c) 2007-2015 Vassilis Rizopoulos. All rights reserved.
module Rutema
  #Rutema supports two kinds of reporters.
  #
  #Block (from en bloc) reporters receive data via the report() method at the end of a Rutema run
  #while event reporters receive events continuously during a run via the update() method
  #
  #Nothing prevents you from creating a class that implements both behaviours
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
  
    class Console<EventReporter
      def update data
        if data["test"] && data["phase"]
          puts "#{data["phase"]} #{data["test"]}"
        elsif data[:message]
          puts data[:message]
        elsif data[:error]
          puts "ERROR: #{data[:error]}"
        elsif data["status"]!=:error
          puts "#{data["test"]} #{data["number"]}-#{data["step_type"]}"
        elsif data["status"]==:error
          puts "FATAL: #{data["test"]} #{data["number"]}-#{data["step_type"]}"
          puts  data.fetch("out","")
          puts data.fetch("error","")
        end
      end
    end
  end
end
