#  Copyright (c) 2007 Vassilis Rizopoulos. All rights reserved.
$:.unshift File.join(File.dirname(__FILE__),"..","..")
require 'rubot/base'
require 'rubot/overseer/configuration'
require 'rubot/overseer/loader'
require 'rubot/overseer/model'
require 'rubot/overseer/callers'
require 'rubot/schedulers/change'
require "rubot/worker/main"
module Rubot
  module Overseer
    class OverseerError<RuntimeError
    end
    #Default value for the log filename
    LOG="rubot_overseer.log"
    #Default value for the configuration file
    CFG="rubot_overseer.cfg"
    #This is the default SQLite filename to use when no database configuration is found
    DB_FILENAME="overseer.db"
    #Coordinator is the object that coordinates all build activities on the server side.
    #
    #It accepts all change events and routes them to the schedulers.
    #
    #It maintains a queue of build requests for every Worker.
    #
    #All persistence issues are delegated to OverseerStatusHandler.
    #
    #Creation of build requests is delegated to the schedulers
    class Coordinator
      INTERNAL_BUILD_DIR="builds"
      attr_reader :workers,:status_handler,:configuration,:rules,:sequence_definitions
      def initialize configuration
        @configuration=configuration
        @logger=configuration.logger
        #use a default STDOUT logger if none provided
        @logger||=Patir.setup_logger
        #init
        @workers=Hash.new
        @rules=Hash.new
        @sequence_definitions=Hash.new
        internal_mode
        #load the extensions
        load_extensions
        #create the status handler
        @status_handler=StatusHandler.new(configuration,@workers)
        @worker_handler.interface=@status_handler
        #create the dispatcher
        @dispatcher= Dispatcher.new(:workers=>@workers,:status_handler=>@status_handler,:logger=>@logger)
        #create the change scheduler
        if @rules.empty?
          @logger.warn("No rule definitions found. Change events will not be handled, ChangeScheduler deactivated.")
        else
          @change_scheduler=Rubot::Schedulers::ChangeScheduler.new(self)
        end
      end

      #This delegates the change_event to the change scheduler
      def change change_event
        @change_scheduler.change(change_event) if @change_scheduler
      end
      #Start a build on __worker__ with the named __sequence__
      def build worker,sequence,change=nil
        @logger.info("Build request for '#{worker}' with sequence '#{sequence}'")
        #create the request
        req=Rubot::BuildRequest.new(worker,change)
        req.request_id=@status_handler.incoming_request(req)
        req.command_sequence=load_sequence(sequence,req)
        req.command_sequence.sequence_id=req.request_id
        return @dispatcher.build(req)
      end
      private
      def load_extensions
        @logger.info("Loading workers")
        load_workers
        @logger.info("Loading rules")
        rule_definitions=Rubot::Overseer.load_extensions(File.join(@configuration.base,RULES),RULE_EXT)
        rule_definitions.each do |name,content|
          ext=Rubot::Overseer::RuleExtension.new(@configuration.base)
          @logger.info("Adding rule '#{name}'")
          @rules[name]=eval(content,ext.get_binding)
        end
        @logger.info("Loading sequence definitions")
        @sequence_definitions=Rubot::Overseer.load_extensions(File.join(@configuration.base,SEQUENCES),SEQUENCE_EXT)
      end
      def load_workers
        worker_definitions=Rubot::Overseer.load_extensions(File.join(@configuration.base,WORKERS),WORKER_EXT)
        if worker_definitions.empty?
          @logger.warn("No worker definition files found")
        else
          worker_definitions.each do |name,content|
            ext=Rubot::Overseer::WorkerExtension.new(name)
            @logger.info("Adding worker '#{name}'")
            @workers[name]=HTTPWorkerCaller.new(eval(content,ext.get_binding))
          end
        end
      end
      def load_internal_worker
         @logger.info("Overseer: Adding internal worker")
         caller_config={:ip=>@configuration.interface[:ip],:port=>@configuration.interface[:port],
           :observer=>@worker_handler,
           :working_directory=>File.join(@configuration.base,INTERNAL_BUILD_DIR)}
         @workers["internal"]=InternalWorkerCaller.new(caller_config)
      end
      def load_sequence name,request
        ext=Rubot::Overseer::SequenceExtension.new(name,request)
        @logger.info("Generating sequence '#{name}'")
        return eval(@sequence_definitions[name],ext.get_binding)
      end
      
      def internal_mode
        worker_config=OpenStruct.new({:name=>"internal",:base=>File.join(@configuration.base,INTERNAL_BUILD_DIR),
          :endpoint=>{:ip=>@configuration.interface[:ip],:port=>@configuration.interface[:port]}})
        @worker_handler=Rubot::Worker::StatusHandler.new(worker_config)
        load_internal_worker
      end
    end
    #This class receives all status messages from the Rubot system as well as all requests generated by the various schedulers.
    #
    #Build requests are saved in the database using Rubot::Model.
    #
    #Status messages are saved as well and then are delegated to the various specialized handlers
    #defined in the configuration
    class StatusHandler
      attr_reader :worker_stati
      def initialize configuration,workers
        @logger=configuration.logger || Patir.setup_logger
        if configuration.database
          @logger.debug("Using configuration file value for database")
          db_file=File.join(configuration.base,configuration.database[:filename])
        else
          @logger.debug("Using default value for database")
          db_file=DB_FILENAME
        end
        Rubot::Model.connect(db_file,@logger)
        reset_workers_configuration(workers)
        #create all the status handlers defined in the configuration
        create_status_handlers(configuration.status_handlers)
      end
      #Handles the worker status messages coming from the rubot workers
      def worker_status data
        @logger.debug("Overseer:Incoming worker status '#{data}'")
        if data.class==Rubot::Worker::Status
          @worker_stati[data.name]=data
          build_status_to_ar(data.current_build) if data.current_build
          return true
        else
          @logger.error("Overseer: #{data.inspect} is not a valid status instance")
          return false
        end
      end
      #Handles the build status messages coming from the rubot workers
      def build_status build_data
        @logger.debug("Incoming build status data: #{build_data}")
        begin 
          #get the local worker status instance
          status_data=@worker_stati[build_data.sequence_runner]
          if status_data
            #update it
            status_data.current_build=build_data
            #set it as online
            status_data.status=:online
            #convert the status class into AR objects
            if build_status_to_ar(build_data)
              #then send it to all registered handlers
              #do it in separate threads, to keep it in parallel (you never know how long a handler will take)
              @handlers.each {|h| Thread.new{h.handle(build_data)} }
              return true
            end
          else
            @logger.error("Could not find rubot worker '#{build_data.sequence_runner}'")
          end
        rescue NoMethodError
          @logger.debug($!)
          @logger.error("Error in incoming status data: #{$!.message}")
        end
        return false
      end
      #Handles the build requests generated by the schedulers
      def incoming_request build_request
        @logger.debug("Persisting #{build_request}")
        #create a new entry
        db_request=Rubot::Model::Request.new
        #it is always pending until we receive status from the worker
        db_request.status="pending"
        #set the builder
        db_request.worker=build_request.worker
        #when was it requested?
        db_request.request_time=build_request.timestamp
        if build_request.change
          db_request.revision = build_request.change.revision
        else
          db_request.revision = "HEAD"
        end
        #save it
        db_request.save
        #remember the record id so we can get to it faster
        build_request.request_id=db_request.id
        return db_request.id
      end
      #Informs the StatusHandler of a change in the workers configuration
      def reset_workers_configuration workers
        #create one entry for every worker
        @worker_stati=Hash.new
        if workers && !workers.empty?
          workers.each do |k,v| 
            st=Rubot::Worker::Status.new(k,"",v.url)
            st.status=:offline
            st.name=k
            @worker_stati[k]=st
          end
        else
          raise OverseerError,"Worker configuration in the StatusHandler was empty"
        end
      end
      private 
      def build_status_to_ar build_status
        begin
          #a sequence is identified by the request id
          request=Rubot::Model::Request.find(build_status.sequence_id)
          #now check if there is a sequence already stored for this request
          sequence=Rubot::Model::Run.find_by_request_id(build_status.sequence_id)
          #not found, create a new one
          unless sequence
            @logger.debug("Creating new sequence entry for request #{build_status.sequence_id}")
            #no run assocated, create a new entry
            sequence=new_sequence(build_status)
          else
            @logger.debug("Found sequence entry for request #{build_status.sequence_id}")
            #update the data
            sequence=update_sequence(sequence,build_status)
          end
          if sequence.status==:running
            request.status="processing"
          else
            request.status="finished"
          end
          #add it to the request
          request.run=sequence
          #save
          request.save
        rescue ActiveRecord::RecordNotFound
          #oh oh, somebody messed up
          @logger.error("Oops, could not find request '#{build_status.sequence_id}'")
          return false
        end
        return true
      end
      def new_sequence build_status
        sequence=Rubot::Model::Run.new
        sequence.name=build_status.sequence_name
        sequence.sequence_runner=build_status.sequence_runner
        sequence.start_time=build_status.start_time
        sequence.stop_time=build_status.stop_time
        sequence.status=build_status.status
        build_status.step_states
        build_status.step_states.each do |number,step_status|
          step=Rubot::Model::Step.new
          step.number=number
          sequence.steps<<step
          update_step(step,step_status)
        end
        sequence.save
        return sequence
      end
      #updates __sequence__ with the data in __build_status__
      def update_sequence sequence,build_status
        #just update the stop time and the status
        sequence.stop_time=build_status.stop_time
        sequence.status=build_status.status
        #and all the steps
        build_status.step_states.each do |number,step_status|
          #step_status is a hash of name,status,output,error,duration}
          step=sequence.steps[number] 
          if step
            @logger.debug("Updating step #{number}")
            update_step(step,step_status)
            step.save
          else
            @logger.warn("Step #{number} not found")
          end
        end
        return sequence
      end
      #updates a Rubot::Model::Step instance from stat status data
      def update_step step, step_status
        step.name=step_status[:name]
        step.status="#{step_status[:status]}"
        step.output=step_status[:output]
        step.error=step_status[:error]
        step.duration=step_status[:duration]
      end
      #creates the status handlers defined in the configuration
      def create_status_handlers handler_definitions
        @logger.info("Creating status handlers")
        #initialize the array
        @handlers=Array.new
        if !handler_definitions
          @logger.info("No additional status handlers defined")
        else
          #cycle the definitions
          handler_definitions.each do |name,definition|
            begin
              #pass the logger to the delegate
              definition[:logger]=@logger
              #instantiate a handler passing the definition
              @handlers<<definition[:class].new(definition)
            rescue
              #ohoh, somebody did a doodoo
              @logger.error("Could not instantiate handler from '#{definition}'")
            end
          end 
        end
      end
    end
    #Dispatcher is the object that manages the how and when of builds.
    #
    #BuildRequest instances come in through the Dispatcher#build_request.
    #
    #Dispatcher caches requests and dispatches them in regular intervals.
    #
    #The frequency of build request dispatching can be set with Dispatcher#check_every
    class Dispatcher
      #The default interval to wait before processing requests
      DEFAULT_INTERVAL=30
      attr_reader :check_interval
      #Initialization parameters for Builder are:
      # :workers - The WorkerCaller instances available
      # :check_interval - optional, the interval in seconds between two queue checks. Default is Dispatcher#DEFAULT_INTERVAL
      # :logger - optional, the logger to use
      def initialize params
        @workers=params[:workers]
        raise Patir::ParameterException,"A Dispatcher needs to know the :workers" unless @workers && !@workers.empty?
        @status_handler=params[:status_handler]
        raise Patir::ParameterException,"A Dispatcher needs to know the :status_handler" unless @status_handler
        #create a queue
        @queue = Queue.new
        @thread=nil
        @check_interval=params[:check_interval]
        @check_interval||=DEFAULT_INTERVAL
        @logger=params[:logger]
        @logger||=Patir.setup_logger
        @thread=start
      end
      
      def build build_request
        @logger.debug("Initiating build")
        #check the status handler
        worker_status=@status_handler.worker_stati[build_request.worker]
        if worker_status         
          if worker_status.online? && worker_status.free?
            #get the appropriate caller
            caller=@workers[build_request.worker]
            if caller
              begin
                @logger.debug("Calling worker")
                return caller.build(build_request)
              rescue
                @logger.error($!)
                raise OverseerError,$!.message
              end
            else
              @logger.error("No WorkerCaller for '#{build_request.worker}'. Request discarded")
              return false
            end
          else
            @logger.info("'#{build_request.worker}' is busy or offline. Queueing request")
            @queue.push(build_request)
            return true
          end
        else
          @logger.error("Worker status for '#{build_request.worker}' not found")
          return false
        end
      end
      #Sets the time interval to use when checking the BuildRequest queue.
      #
      #Comes in effect at the end of the current check cycle.
      def check_every time_in_seconds
        @check_interval=time_in_seconds
      end

      #Returns an Array with pending build requests
      def pending_builds
        ret=Array.new
        while !@queue.empty?
          ret<<@queue.pop
        end
        ret.each{|e| @queue.push(e)}
        return ret
      end
      private
      #Start a thread that periodically looks in the queue, extracts any build requests and forwards them to the
      #appropriate worker.
      #
      #Returns the handle to the created thread.
      def start
        @thread=Thread.new do
          while true do
            begin#this will handle connection errors etc.
              #check if there is something in the queue
              @logger.debug("Checking queue")
              if @queue.size>0
                queued_requests=@queue.size
                while queued_requests>0
                  request=@queue.pop
                  build(request)
                  queued_requests-=1
                end
              end
            rescue
              @logger.debug($!)
              @logger.error("Error in the Dispatcher: #{$!.message}")
            end
            #go to sleep for the interval
            sleep(@check_interval)
          end  #while
        end#thread
        @logger.info("Dispatcher started")
        return @thread
      end

    end
    

  end
end