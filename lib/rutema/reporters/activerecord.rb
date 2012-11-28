#  Copyright (c) 2007-2010 Vassilis Rizopoulos. All rights reserved.
require 'rutema/models/activerecord'

module Rutema
  #The ActiveRecordReporter will store the results of a test run in a database using ActiveRecord.
  class ActiveRecordReporter
    #The required keys in this reporter's configuration are:
    # :db - the database configuration. A Hash with the DB adapter information
    #  :db=>{:database=>"sample.rb"}
    def initialize definition
      @logger=definition[:logger]
      @logger||=Patir.setup_logger
      database_configuration = definition[:db]
      raise "No database configuration defined, missing :db configuration key." unless database_configuration
      $:.unshift File.join(File.dirname(__FILE__),"..","..")
      require 'rutema/models/activerecord'
      Rutema::ActiveRecord.connect(database_configuration,@logger)
      @logger.info("Reporter #{self.to_s} registered")
    end
    #We get all the data for a Rutema::ActiveRecord::Run entry in here.
    #
    #If the configuration is given and there is a context defined, this will be YAML-dumped into Rutema::ActiveRecord::Run#context
    def report specifications,runner_states,parse_errors,configuration
      run_entry=Rutema::ActiveRecord::Run.new
      if configuration && configuration.context
        run_entry.context=configuration.context
      end
      parse_errors.each do |pe|
        er=Rutema::ActiveRecord::ParseError.new()
        er.filename=pe[:filename]
        er.error=pe[:error]
        run_entry.parse_errors<<er
      end
      runner_states.compact!
      runner_states.each do |scenario|
        sc=Rutema::ActiveRecord::Scenario.new
        sc.name=scenario.sequence_name
        sc.number=scenario.sequence_id
        sc.start_time=scenario.start_time
        sc.stop_time=scenario.stop_time
        sc.status=scenario.status.to_s
        #get the specification for this scenario
        spec=specifications[scenario.sequence_name]
        if spec
          sc.version=spec.version if spec.has_version?
          sc.title=spec.title
          sc.description=spec.description
        else
          @logger.debug("Could not find specification for #{scenario.sequence_name}")
          sc.title=scenario.sequence_name
          sc.description=""
        end
        if scenario.strategy==:attended
          sc.attended=true
        else
          sc.attended=false
        end
        scenario.step_states.each do |number,step|
          st=Rutema::ActiveRecord::Step.new
          st.name=step[:name]
          st.number=number
          st.status="#{step[:status]}"
          st.output=sanitize(step[:output])
          st.error=sanitize(step[:error])
          st.duration=step[:duration]
          sc.steps<<st
        end
        run_entry.scenarios<<sc
      end
      run_entry.save!
      "activerecord reporter done"
    end
    def to_s#:nodoc:
      "ActiveRecordReporter"
    end
    private
    def sanitize text
      return text.gsub("\000","") if text
      return ""
    end
  end
end