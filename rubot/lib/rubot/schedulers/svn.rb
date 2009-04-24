module Rubot
  module Schedulers
    #The SvnPollScheduler regularly polls a subversion repository for changes and submits BuildRequests according to the specified rules
    class SvnPollScheduler
      include RubotSchedulerInterface
      attr_accessor :rules,:builders
      attr_reader :poll_tasks

      def initialize params
        raise "No parameters defined" unless params
        @logger=params[:logger]
        @logger||=Patir.setup_logger
        @queue_manager=params[:queue_manager]
        raise "No queue manager provided" unless @queue_manager
        @poll_tasks=params[:poll].collect do
          |p| 
          PollTask.new(p.merge({ :logger => @logger, :queue_manager => @queue_manager }))
        end if params[:poll]
        @poll_tasks||=Array.new
        @logger.info "There are #{@poll_tasks.size} subversion poll tasks defined."
        @check_interval=params[:check_interval]
        @check_interval||=600
        start
      end

      def start
        @thread = Thread.new {
          @logger.info "Subversion Poll loop started, checking every #{@check_interval} seconds."
          while true
            for pollTask in @poll_tasks
              begin
                pollTask.poll
              rescue StandardError => e
                @logger.error(e.message)
                @logger.debug(e)
              end
            end
            sleep @check_interval
          end
        }
      end

      def stop
        @thread.kill
      end

    end
  end
end