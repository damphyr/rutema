require 'yaml'

module Rutema
  
  module YAML
    #Experimental reporter used to dump the data of a run on disk
    #
    #The following configuration keys are used by YAML::Reporter:
    #
    #:filename - the filename to use to save the YAML dump. Default is 'rutema.yaml'
    class Reporter
      DEFAULT_FILENAME="rutema.yaml"
    
      def initialize definition
        @logger=definition[:logger]
        @logger||=Patir.setup_logger
        @filename=definition[:filename]
        @filename||="rutema.yaml"
        @logger.info("Reporter #{self.to_s} registered")
      end
      
      #We get all the data from a test run in here.
      def report specifications,runner_states,parse_errors,configuration
        run_entry={}
        if configuration && configuration.context
          run_entry[:context]=configuration.context
        end
        run_entry[:parse_errors]=parse_errors
        runner_states.compact!
        run_entry[:runner_states]=runner_states
        File.open(@filename,"wb") {|f| f.write( ::YAML.dump(run_entry))}
      end
    end
  end
end