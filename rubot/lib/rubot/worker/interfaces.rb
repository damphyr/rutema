module Rubot
  module Worker
    #This is the client for updating the Worker status on the Overseer through it's RESTful interface
    class HTTPStatusInterface
      def initialize ip,port,logger

      end
      def worker_status data
        #serialize the data with YAML
        #post it 
        # http://ip:port/status/sequence_runner POST
      end
      def build_status data
        #serialize the data with YAML
        #post it 
        # http://ip:port/status/sequence_runner POST
      end
    end

  end
end