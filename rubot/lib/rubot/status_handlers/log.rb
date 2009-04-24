require 'patir/base'
module Rubot
  module StatusHandlers
    #This status handler just logs the status messages using Logger.
    #
    #It will instantiate a logger that logs on the console unless otherwise configured.
    class LogStatusHandler
      def initialize level=Logger::INFO,filename=nil
        @logger=Rubot.setup_logger(filename,level)
      end
      def handle status_data
        @logger.info(status_data.to_s)
      end
    end
  end
end