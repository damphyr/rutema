require 'rutema/model'

module Rutema
    class CouchDBReporter
      def initialize definition
        @logger=definition[:logger]
        @logger||=Patir.setup_logger
        database_configuration = definition[:db]
        raise "No database configuration defined, missing :db configuration key." unless database_configuration
        @database=Rutema::CouchDB.connect(database_configuration)
        @logger.info("Reporter #{self.to_s} registered")
      end
      
      #We get all the data for a Rutema::CouchDB::Model::Run entry in here.
      def report specifications,runner_states,parse_errors,configuration
        run_entry=Rutema::CouchDB::Model::Run
        run_entry.database=@database
        if configuration && configuration.context
          run_entry.context=configuration.context
        end
        run_entry.parse_errors=parse_errors
        scenarios=[]
        runner_states.compact!
        runner_states.each { |scenario| scenarios<<format_scenario(scenario,specifications)}
        run_entry.scenarios=scenarios
        run_entry.save
        "couchdb reporter done"
      end
      
      def to_s
        "CouchDBReporter"
      end
      private 
      def format_scenario scenario,specifications
        sc={}
        sc[:name]=scenario.sequence_name
        sc[:number]=scenario.sequence_id
        sc[:start_time]=scenario.start_time
        sc[:stop_time]=scenario.stop_time
        sc[:status]=scenario.status.to_s
        #get the specification for this scenario
        spec=specifications[sc[:name]]
        if spec
          sc[:version]=spec.version if spec.has_version?
          sc[:title]=spec.title
          sc[:description]=spec.description
        else
          @logger.debug("Could not find specification for #{sc[:name]}")
          
          sc[:title]=sc[:name]
          sc[:description]=""
        end
        if scenario.strategy==:attended
          sc[:attended]=true
        else
          sc[:attended]=false
        end
        sc[:steps]=scenario.step_states
        return sc
      end
    end
  end
end