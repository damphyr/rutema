# Copyright (c) 2007-2020 Vassilis Rizopoulos. All rights reserved.

# frozen_string_literal: true

module Rutema
  ##
  # Rutema::Dispatcher functions as a demultiplexer between Rutema::Engine and
  # the various reporters
  #
  # In stream mode the incoming queue is popped periodically and the messages
  # are distributed to the queues of any subscribed event reporter.
  #
  # By default this includes Rutema::Reporters::Collector which is then used at
  # the end of a run to provide the collected data to all registered block mode
  # reporters.
  class Dispatcher
    ##
    # The interval between queue operations
    INTERVAL = 0.01

    ##
    # Initialize a new Rutema::Dispatcher with a given input +queue+ and
    # +configuration+
    def initialize(queue, configuration)
      @queue = queue
      @queues = {}
      @streaming_reporters = []
      @block_reporters = []
      @collector = Rutema::Reporters::Collector.new(nil, self)
      if configuration.reporters
        instances = configuration.reporters.values.map do |v|
          instantiate_reporter(v, configuration) if v[:class] \
            != Reporters::Summary
        end
        instances.compact
        @streaming_reporters, = instances.partition { |rep| rep.respond_to?(:update) }
        @block_reporters, = instances.partition { |rep| rep.respond_to?(:report) }
      end
      @streaming_reporters << @collector
      @configuration = configuration
    end

    ##
    # Subscribe to a message queue with given +identifier+
    #
    # The passed queue will have data pushed by the Rutema::Dispatcher instance
    def subscribe(identifier)
      @queues[identifier] = Queue.new
      @queues[identifier]
    end

    ##
    # Begin dispatching messages in new thread
    def run!
      puts "Running #{@streaming_reporters.size} streaming reporters" if $DEBUG
      @streaming_reporters.each(&:run!)
      @thread = Thread.new do
        loop do
          dispatch
          sleep INTERVAL
        end
      end
    end

    ##
    # Report all results to the internally held block reporters
    def report(specs)
      @block_reporters.each do |r|
        r.report(specs, @collector.states, @collector.errors)
      end
      Reporters::Summary.new(@configuration, self).report(specs, @collector.states, @collector.errors)
    end

    ##
    # If separate thread got started with #run! #flush the queue and exit
    # streaming reporters
    def exit
      puts 'Exiting main dispatcher' if $DEBUG
      return unless @thread

      flush
      @streaming_reporters.each(&:exit)
      Thread.kill(@thread)
    end

    private

    ##
    # If separate thread got started with #run! dispatch messages each INTERVAL
    # seconds until queue is emptied
    def flush
      puts 'Flushing queues' if $DEBUG
      return unless @thread

      until @queue.empty?
        dispatch
        sleep INTERVAL
      end
    end

    ##
    # Create a new instance of the class in the +:class+ key of +definition+
    # and pass +configuration+ to it
    def instantiate_reporter(definition, configuration)
      if definition[:class]
        klass = definition[:class]
        return klass.new(configuration, self)
      end
      nil
    end

    ##
    # If there is a message in the incoming queue dispatch it to all subscribers
    def dispatch
      return if @queue.empty?

      data = @queue.pop
      @queues.each { |_, q| q.push(data) } if data
    end
  end
end
