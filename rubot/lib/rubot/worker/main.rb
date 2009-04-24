#  Copyright (c) 2008 Vassilis Rizopoulos. All rights reserved.
$:.unshift File.join(File.dirname(__FILE__),"..")
require 'fileutils'
require 'worker/configuration'

require 'rubot/gems'

module Rubot
  module Worker
    #Default value for the log filename
    LOG="rubot_worker.log"
    #Default value for the configuration file
    CFG="rubot_worker.cfg"
    #This is the coordination object for the worker side of the system 
    class Coordinator
      attr_reader :configuration
      attr_accessor :runner
      #_configuration_ is a Rubot::Worker::Configuration instance that contains the user defined configuration
      #
      #Apart from the user-adaptable parameters defined in Rubot::Worker::Configuration the Configuration instance also should respond to:
      # Configuration#logger - the logger instance to use
      # Configuration#interface - the client interface to use for sending messages to the Overseer (see HTTPStatusInterface for an implementation)
      def initialize configuration
        if configuration.respond_to?(:base)
          @configuration=configuration
          #create it
          FileUtils.mkdir_p(@configuration.base)
          #set the logger for this worker
          @logger=configuration.logger if configuration.respond_to?(:logger)
          @logger||=Patir.setup_logger
          @configuration.logger=@logger        
          #create the status information handler
          @handler=StatusHandler.new(@configuration)
          #create the runner
          @runner=BuildRunner.new(@configuration.base,@handler)
          #log and update status
          @logger.debug("Worker with base #{@configuration.base} created")
          @logger.info("Worker #{@configuration.name} created")
        else
          raise Patir::ConfigurationException,"Ilegal configuration for Worker::Coordinator: #{configuration.inspect}"
        end
      end
      #Return the worker's status
      def status
        return @handler.status
      end
      #Returns true if there is no BuildRunner for the builder or if it's not running at the moment
      def free?
        return @runner.free?
      end    
      #Starts a build if the associated BuildRunner is not busy
      def build build_request
        if check_request(build_request)
          #BuildRunner knows if it's busy
          if @runner.build(build_request)
            @logger.info("Executing #{build_request.inspect} with id '#{build_request.request_id}'")
            return true
          else
            @logger.warn("BuildRunner is busy")
            return false
          end
        end
        return false
      end
      private
      def check_request request
        #TODO: check what we are getting.
        #that build_request quacks like a BuildRequest
        if request
          return true 
        else
          @logger.error("No BuildRequest supplied")
        end
        return false
      end
      # def update_status params
      #         @handler.update(params) if params
      #       end
    end
    #Status delivers information on the Worker, the build stati (as Patir::CommandSequenceStatus instances), environment settings (base directory etc.)
    #and it's state (:online or :offline). This last one is maintained by the Overseer, a Worker always considers itself online.
    class Status
      #status can be :online or :offline. This is maintained by the Overseer, the Worker will always set it's status to :online when notifying :).
      attr_accessor :status,:base,:name,:url
      attr_reader :current_build
      def initialize name,base,url
        @name=name
        @url=url
        @status=:online
        @base=File.expand_path(base)
        @current_build=nil
      end
      #Returns true if the Worker is considered online
      def online?
        return @status!=:offline
      end
      #Returns false if the Worker is currently building
      def free?
        if @current_build
          return true if @current_build.completed?
        else
          return true
        end
        return false
      end
      #Adds information about a Build
      def current_build=build_status
        begin
          build_status.sequence_runner=@name
          @current_build=build_status
          return build_status
        rescue NoMethodError
          $stderr.puts "My build_status is not quacking sequence_runner: #{build_status.to_s}" if $DEBUG
          return nil
        end
      end
      def to_s
        "Worker at #{@url} is #{@status}\n#{@current_build.to_s}"
      end
    end
    #This is the central information gathering object for the Worker module, gathering the stati of the worker, the runner and the builds.
    #
    #It is registered as the observer for all objects spawned in a Worker instance. 
    #
    #It handles the following keys
    # :debug, :info, :warn, :error, :fatal, :unknown - redirected to the logger
    # :build_status - updates and forwards the status of a build
    # :status - forwards the complete worker status
    class StatusHandler
      attr_accessor :status
      attr_reader :interface
      #Configuration is an instance of 
      def initialize configuration
        begin
          #create the status object
          @status=Status.new(configuration.name,
            configuration.base,
            url(configuration.endpoint[:ip],
            configuration.endpoint[:port]))
          #setup the logger
          @logger=configuration.logger
          @logger||=Patir.setup_logger
          if configuration.respond_to?(:interface)
            @interface=configuration.interface 
          else
            @logger.error("Worker: No interface defined in the configuration. No way to send stati to the overseer")
          end
          update(:status=>:online) if @interface
        rescue
          raise Patir::ConfigurationException,"Ilegal configuration for Worker::StatusHandler: #{configuration.inspect}"
        end
      end
      #params is a hash where following keys can be used
      #
      #:debug,:info,:warn,:fatal,:error and :unknown 
      #to log a message in the logger logging at the corresponding level
      #
      #:sequence_status=> build sequence status
      #:status=> worker status
      def update params
        @logger.debug("StatusHandler:Incoming message #{params.inspect}")
        begin
          @logger.debug(params[:debug]) if params[:debug]
          @logger.info(params[:info])  if params[:info]
          @logger.warn(params[:warn])  if params[:warn]
          @logger.fatal(params[:fatal])  if params[:fatal]
          @logger.error(params[:error])  if params[:error]
          @logger.unknown(params[:uknown])  if params[:unknown]
          build_status(params[:sequence_status]) if params[:sequence_status]
          worker_status(params[:status]) if params[:status]
        end unless params.empty?
        return @status
      end
      def interface= interface
        @interface=interface
        update(:status=>:online)
      end
      private
      def build_status build_status
        #update the corresponding build status
        @logger.debug("StatusHandler:Sending build status '#{build_status}'")
        @status.current_build=build_status
        if @status.current_build
          begin
            #only send the build status
            @interface.build_status(@status.current_build) if @interface
          rescue
            @logger.error("BuildStatus interface failure: #{$!.message}")
            @logger.debug($!)
          end
        else
          @logger.error("Could not add status '#{build_status.inspect}'")
        end
      end
      def worker_status status
        @logger.debug("StatusHandler:Updating worker status with '#{status}'")
        @status.status=status
        begin
          #send the complete status
          @interface.worker_status(@status) if @interface
        rescue
          @logger.error("WorkerStatus interface failure: #{$!.message}")
          @logger.debug($!)
        end
      end
      def url ip,port
        return "http://#{ip}:#{port}"
      end
    end  
    #The BuildRunner is the object that actually executes a build. 
    #
    #It will do so in a separate thread and under it's own directory (the _wd_ parameter).
    class BuildRunner
      attr_reader :working_directory,:build_thread
      #
      def initialize wd,observer
        #get the observer to use - this is where the BuildStatus messages go -
        @observer=observer
        @working_directory=wd
        #create the directory
        FileUtils.mkdir_p(@working_directory)
      end
      #tells you if the runner is free for work
      def free?
        return (!@build_thread || @build_thread.stop?)
      end
      #attempts to start a build, will return false if the runner is not free
      def build request
        #are we busy? what's the status of my build process?
        #is there a thread running?
        if free?
          #it stopped, kill it
          @build_thread.kill if @build_thread
          #spawn a new thread and run the process
          if request.command_sequence
            @build_thread=build_thread(request.command_sequence)
          else
            #sneaky way to log
            @observer.update(:error=>"No command sequence defined in '#{request.inspect}'")
          end
          #return and let the process send status messages
          return @build_thread
        else
          #it is still running, deny them
          return false
        end
      end
      private
      #this will spawn a process with a copy of the BuildProcess instance and let it loose
      def build_thread command_sequence
        #start observing it
        command_sequence.add_observer(@observer)
        #sneaky way to log
        @observer.update(:info=>"Build for sequence #{command_sequence.name}")
        #create the thread that runs it
        Thread.new(command_sequence,@working_directory) do |sequence,base|
          #change into the base directory
          Dir.chdir(base) do
            begin
              #run the process
              sequence.run
            rescue
              @observer.update(:error=>"Sequence #{sequence} failed: #{$!.message}",:debug=>$!)
            end
          end
        end
      end
    end
  end
end