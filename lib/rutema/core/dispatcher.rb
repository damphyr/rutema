# Copyright (c) 2007-2020 Vassilis Rizopoulos. All rights reserved.

# frozen_string_literal: true

module Rutema
  #The Rutema::Dispatcher functions as a demultiplexer between Rutema::Engine and the various reporters.
  #
  #In stream mode the incoming queue is popped periodically and the messages are destributed to the queues of any subscribed event reporters.
  #
  #By default this includes Rutema::Reporters::Collector which is then used at the end of a run to provide the collected data to all registered block mode reporters 
  class Dispatcher
    #The interval between queue operations
    INTERVAL=0.01

    ##
    # Initialize a new Rutema::Dispatcher with a given input +queue+ and
    # +configuration+
    def initialize queue,configuration
      @queue = queue
      @queues = {}
      @streaming_reporters=[]
      @block_reporters=[]
      @collector=Rutema::Reporters::Collector.new(nil,self)
      if configuration.reporters
        instances=configuration.reporters.values.map{|v| instantiate_reporter(v,configuration) if v[:class] != Reporters::Summary}.compact
        @streaming_reporters,_=instances.partition{|rep| rep.respond_to?(:update)}
        @block_reporters,_=instances.partition{|rep| rep.respond_to?(:report)}
      end
      @streaming_reporters<<@collector
      @configuration=configuration
    end

    ##
    # Subscribe to a message queue with given +identifier+
    #
    # The passed queue will have data pushed by the Rutema::Dispatcher instance
    def subscribe identifier
      @queues[identifier]=Queue.new
      return @queues[identifier]
    end

    ##
    # 
    def run!
      puts "Running #{@streaming_reporters.size} streaming reporters" if $DEBUG
      @streaming_reporters.each {|r| r.run!}
      @thread=Thread.new do
        while true do
          dispatch()
          sleep INTERVAL
        end
      end
    end

    ##
    # Report all results to the internally held block reporters
    def report specs
      @block_reporters.each do |r|
        r.report(specs,@collector.states,@collector.errors)
      end
      Reporters::Summary.new(@configuration,self).report(specs,@collector.states,@collector.errors)
    end

    ##
    # If separate thread got started with #run! #flush the queue and exit
    # streaming reporters
    def exit
      puts "Exiting main dispatcher" if $DEBUG
      if @thread
        flush
        @streaming_reporters.each {|r| r.exit}
        Thread.kill(@thread)
      end
    end

    private

    ##
    # If separate thread got started with #run! dispatch messages each INTERVAL
    # seconds until queue is emptied
    def flush
      puts "Flushing queues" if $DEBUG
      if @thread
        while @queue.size>0 do
          dispatch()
          sleep INTERVAL
        end
      end
    end

    ##
    # Create a new instance of the class in the +:class+ key of +definition+
    # and pass +configuration+ to it
    def instantiate_reporter definition,configuration
      if definition[:class]
        klass=definition[:class]
        return klass.new(configuration,self)
      end
      return nil
    end

    ##
    # If there is a message in the incoming queue dispatch it to all subscribers
    def dispatch
      if @queue.size>0
        data=@queue.pop
        @queues.each{ |i,q| q.push(data) } if data
      end
    end
  end
end
