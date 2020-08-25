#  Copyright (c) 2007-2017 Vassilis Rizopoulos. All rights reserved.
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
            data=@queue.pop
            begin
              update(data) if data
            rescue
              puts "#{self.class} failed with #{$!.message}"
              raise
            end
          end
        end
      end

      def update data
      end

      def exit
        puts "Exiting #{self.class}" if $DEBUG
        if @thread
          puts "Reporter died with #{@queue.size} messages in the queue" unless @thread.alive?
          while @queue.size>0 && @thread.alive? do
            sleep 0.1
          end
          Thread.kill(@thread)
        end
      end
    end
    #This reporter is always instantiated and collects all messages fired by the rutema engine
    #
    #The collections of errors and states are then at the end of a run fed to the block reporters
    class Collector<EventReporter
      attr_reader :errors,:states
      def initialize params,dispatcher
        super(params,dispatcher)
        @errors=[]
        @states={}
      end

      def update message
        case message
        when RunnerMessage
          test_state=@states[message.test]
          if test_state
            test_state<<message
          else
            test_state=Rutema::ReportState.new(message)
          end
          @states[message.test]=test_state
        when ErrorMessage
          @errors<<message
        end
      end
    end
    #A very simple event reporter that outputs to the console
    #
    #It has three settings: off, normal and verbose.
    #
    #Example configuration:
    # cfg.reporter={:class=>Rutema::Reporters::Console, "mode"=>"verbose"}
    class Console<EventReporter
      def initialize configuration,dispatcher
        super(configuration,dispatcher)
        @mode=configuration.reporters.fetch(self.class,{})["mode"]
      end
      def update message
        unless @mode=="off"
          case message
          when RunnerMessage
            if message.status == :error
              puts "FATAL|#{message.to_s}"
            elsif message.status == :warning
              puts "WARNING|#{message.to_s}"
            else
              puts "#{message.to_s} #{message.status}." if @mode=="verbose"
            end
          when ErrorMessage
            puts message.to_s 
          when Message
            puts message.to_s if @mode=="verbose"
          end
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
        states.each{|k,v| failures<<v.test if v.status==:error}

        unless @silent
          count_tests_run = states.select { |name, state| !state.is_special }.count
          puts "#{errors.size} errors. #{count_tests_run} test cases executed. #{failures.size} failed"
          unless failures.empty?
            puts "Failures:"
            puts specs.map{|spec| "  #{spec.name} - #{spec.filename}" if failures.include?(spec.name)}.compact.join("\n")
          end
        end
        return failures.size+errors.size
      end
    end
  end

  module Utilities
    require "fileutils"
    def self.write_file filename,content
      FileUtils.mkdir_p(File.dirname(filename),:verbose=>false)
      File.open(filename, 'wb') {|f| f.write(content) }
    end  
  end
end
