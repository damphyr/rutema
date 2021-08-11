#  Copyright (c) 2007-2021 Vassilis Rizopoulos. All rights reserved.

require 'json'
require_relative "../core/reporter"

module Rutema
  module Reporters
    #Experimental reporter used to dump the data of a run on disk
    #
    #The following configuration keys are used by Rutema::Reporters::JSON
    #
    # filename - the filename to use to save the YAML dump. Default is 'rutema.results.json'
    class JSON<Rutema::Reporters::BlockReporter
      #Default report filename
      DEFAULT_FILENAME="rutema.results.json"

      def initialize configuration,dispatcher
        super(configuration,dispatcher)
        @filename=configuration.reporters.fetch(self.class,{}).fetch("filename",DEFAULT_FILENAME)
      end

      #We get all the data from a test run in here.
      def report specs,states,errors
        run_entry={}
        run_entry["specs"]=specs.size
        if @configuration && @configuration.context
          run_entry["context"]=@configuration.context
        end
        run_entry["errors"]=errors
        run_entry["states"]=states
        
        Rutema::Utilities.write_file(@filename,::JSON.dump(run_entry))
      end
    end
  end
end
