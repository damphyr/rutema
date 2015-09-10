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
      def report specifications,states,errors
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
  
    class Collector<EventReporter
      attr_reader :errors,:states
      def initialize params,dispatcher
        super(params,dispatcher)
        @errors=[]
        @states={}
      end

      def update data
        if data[:error]
          @errors<<data
        elsif data[:test] && data['status']
          @states[data[:test]]||=[]
          @states[data[:test]]<<data
        end
      end
    end

    class Console<EventReporter
      def initialize configuration,dispatcher
        super(configuration,dispatcher)
        @mode=configuration.reporters.fetch(self.class,{})["mode"]
      end
      def update data
        if data[:error]
          puts ">ERROR: #{data.fetch(:test,"")} #{data[:error]}" unless @mode=="off"
        elsif data[:test] 
          if data["phase"]
            puts ">#{data["phase"]} #{data[:test]}" unless @mode=="silent" || @mode=="off"
          elsif data[:message]
            puts ">#{data[:test]} #{data[:message]}" unless @mode=="silent" || @mode=="off"
          elsif data["status"]==:error
            if @mode!="off"
              puts ">FATAL: #{data[:test]}(#{data["number"]}) failed"
              puts data.fetch("out","")
              puts data.fetch("err","")
            end
          end
        elsif data[:message] 
          puts ">#{data[:message]}" unless @mode=="silent" || @mode=="off"
        end
      end
    end

    class Summary<BlockReporter
      def initialize configuration,dispatcher
        super(configuration,dispatcher)
        @silent=configuration.reporters.fetch(self.class,{})["silent"]
      end
      def report specs,states,errors
        failures=[]
        states.each do |k,v|
          failures<<k if v.last['status']==:error
        end
        unless @silent
          puts "#{errors.size} errors. #{states.size} test cases executed. #{failures.size} failed"
          unless failures.empty?
            puts "Failures:"
            puts specs.map{|spec| "  #{spec.name} - #{spec.filename}" if failures.include?(spec.name)}.compact.join("\n")
          end
        end
        return failures.size+errors.size
      end
    end
  end
end
