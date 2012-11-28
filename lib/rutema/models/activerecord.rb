#  Copyright (c) 2007-2010 Vassilis Rizopoulos. All rights reserved.
$:.unshift File.join(File.dirname(__FILE__),'..','..')
require 'rutema/models/base'
require 'active_record'

#this fixes the AR Logger hack that annoys me sooooo much
class Logger
  private
  def format_message(severity, datetime, progname, msg)
    (@formatter || @default_formatter).call(severity, datetime, progname, msg)
  end
end
module Rutema
  module ActiveRecord
    #This is the schema for the AR database used to store test results
    #
    #We store the RutemaConfiguration#context for every run so that reports for past runs can be recreated without running the actual tests again.
    class Schema< ::ActiveRecord::Migration
      def self.up
        create_table :runs do |t|
          t.column :context, :string
        end

        create_table :scenarios do |t|
          t.column :name, :string, :null=>false
          t.column :run_id,:integer, :null=>false
          t.column :attended,:bool, :null=>false
          t.column :status, :string,:null=>false
          t.column :number,:integer
          t.column :start_time, :datetime,:null=>false
          t.column :stop_time, :datetime
          t.column :version, :string
          t.column :title, :string
          t.column :description, :string
        end

        create_table :steps do |t|
          t.column :scenario_id,:integer, :null=>false
          t.column :name, :string
          t.column :number, :integer,:null=>false
          t.column :status, :string,:null=>false
          t.column :output, :text
          t.column :error, :text
          t.column :duration, :decimal
        end

        create_table :parse_errors do |t|
          t.column :filename, :string,:null=>false
          t.column :error, :string
          t.column :run_id,:integer, :null=>false
        end
      end
    end
    class Run< ::ActiveRecord::Base
      has_many :scenarios
      has_many :parse_errors
      serialize :context    
    end
    class Scenario< ::ActiveRecord::Base
      belongs_to :run
      has_many :steps
    end
    class Step< ::ActiveRecord::Base
      belongs_to :scenario
    end
    class ParseError< ::ActiveRecord::Base
      belongs_to :run
    end
    #Exports the contents of the database/model as a yaml dump
    class Export
      def initialize params
        @logger = params[:logger]
        @logger ||= Patir.setup_logger
        @result_set_size = params[:result_set_size]
        @result_set_size ||= 1000
        @currently_on_no=0
        database_configuration = params[:db]
        raise "No database configuration defined, missing :db configuration key." unless database_configuration
        ActiveRecord.connect(database_configuration,@logger)
      end
      def next
        @logger.info("Found #{Run.count} runs") if @currently_on_no==0
        @logger.info("Exporting from #{@currently_on_no} to #{@currently_on_no+@result_set_size}")
        export(@result_set_size)
      end
      def all
        @logger.info("Found #{Run.count} runs")
        export(nil)
      end
      private 
      def export offset=nil
        if offset
          runs=Run.find(:all,:order=>"id ASC",:limit=>@result_set_size,:offset=>@currently_on_no)
          @currently_on_no+=offset
        else
          runs=Run.find(:all)
        end
        return nil if runs.empty?
        export=[]
        runs.each do |run|
          e={:parse_errors=>[],:scenarios=>[],:context=>run.context}
          run.parse_errors.each { |pe| e[:parse_errors]<<{:filename=>pe.filename, :error=>pe.error} }
          run.scenarios.each { |sc| e[:scenarios]<<export_scenario(sc)  }
          export<<e
          @logger.debug("Exported #{run.id}")
        end
        return export
      end
      def export_scenario sc
        scenario={:name=>sc[:name],
          :attended=>sc[:attended],
          :status=>sc[:status],
          :number=>sc[:number],
          :start_time=>sc[:start_time], 
          :stop_time=>sc[:stop_time],
          :version=>sc[:version],
          :title=>sc[:title], 
          :description=>sc[:description],
          :steps=>[]
        }
        sc.steps.each do |step|
          st={:name=>step[:name],
            :number=>step[:number], 
            :status=>step[:status], 
            :output=>step[:output], 
            :error=>step[:error],
            :duration=>step[:duration]
          }
          scenario[:steps]<<st
        end
        return scenario
      end
    end  
    #Establishes an ActiveRecord connection
    def self.connect cfg,logger
      conn=cnct(cfg,logger)
      Schema.migrate(:up) if perform_migration?(cfg)
    end
    private
    #Establishes an active record connection using the cfg hash
    #There is only a rudimentary check to ensure the integrity of cfg
    def self.cnct cfg,logger
      if cfg[:adapter] && cfg[:database]
        logger.debug("Connecting to #{cfg[:database]}")
        return ::ActiveRecord::Base.establish_connection(cfg)
      else
        raise Rutema::ConnectionError,"Erroneous database configuration. Missing :adapter and/or :database"
      end
    end
    def self.perform_migration? cfg
      return true if cfg[:migrate]
      #special case for sqlite3
      if cfg[:adapter]=="sqlite3" && !File.exists?(cfg[:database])
        return true
      end
      return false
    end
  end
end