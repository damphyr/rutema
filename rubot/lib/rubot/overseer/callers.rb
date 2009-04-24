
module Rubot
  module Overseer
    class WorkerCaller
       attr_reader :name,:ip,:port
        def initialize params
          @name=params[:name]
          @ip=params[:ip]
          @port=params[:port]
          @logger=params[:logger]
          @logger||=Patir.setup_logger
        end
        #forwards a build request using the RESTfull interface of Worker
        def build request
          raise "Not Implemented"
        end
        #URL to access teh worker
        def url
          return "http://#{@ip}:#{@port}/"
        end
    end
    #This class sends the build requests to a Worker
    class HTTPWorkerCaller<WorkerCaller
      #forwards a build request using the RESTfull interface of Worker
      def build request
        #TODO: man, put some errorhandling here
        res = Net::HTTP.post_form(URI.parse("#{url}/build"),{'build_request'=>request})
        return true
      end 
    end
 
    class InternalWorkerCaller<WorkerCaller
      def initialize params
        super(params)
        @runner=Rubot::Worker::BuildRunner.new(params[:working_directory],params[:observer])
      end
      def build request
        @runner.build(request)
      end
    end
  end
end
