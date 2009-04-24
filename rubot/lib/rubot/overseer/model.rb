#  Copyright (c) 2007 Vassilis Rizopoulos. All rights reserved.
$:.unshift File.join(File.dirname(__FILE__),"..","..")
require 'rubot/gems'
#this fixes the AR Logger hack that annoys me sooooo much
class Logger
  private
  def format_message(severity, datetime, progname, msg)
    (@formatter || @default_formatter).call(severity, datetime, progname, msg)
  end
end

module Rubot
  #The ActiveRecord model for rubot
  module Model
    def self.connect db_file,logger
      ActiveRecord::Base.logger = logger if logger
      if db_file
        if ActiveRecord::Base.connected?
          logger.info("Using cached database connection") if logger
        else
          ActiveRecord::Base.establish_connection(:adapter=>"sqlite3", :database=>db_file )
          if File.exist?(db_file) || db_file==":memory:"
            logger.info("Connecting with database '#{db_file}'") if logger
          else
            logger.info("Creating database at '#{db_file}'") if logger
            create_db unless File.exists?(db_file)
          end
        end
      else
        logger.fatal("No database source defined") if logger
        exit 1
      end
    end
     
    def self.create_db
      Schema.migrate(:up)
    end
    
    class Schema <ActiveRecord::Migration
      def self.up
        create_table :requests do |t|
          t.column :request_time,:datetime,:null=>false
          t.column :status,:string
          t.column :worker,:string,:null=>false
          t.column :revision,:strings
        end
        
        create_table :runs do |t|
          t.column :start_time, :datetime,:null=>false
          t.column :stop_time, :datetime
          t.column :sequence_runner,:string,:null=>false
          t.column :name,:string,:null=>false
          # :running, :successful
          t.column :status,:string,:null=>false
          t.column :request_id,:integer
        end
        
        create_table :steps do |t|
          t.column :run_id,:integer, :null=>false
          t.column :name, :string
          t.column :number, :integer,:null=>false
          t.column :status, :string,:null=>false
          t.column :output, :text
          t.column :error, :text
          t.column :duration, :integer
        end
      end
    end
    
    class Request<ActiveRecord::Base
      has_one :run
      acts_as_reportable
      
      def self.latest_request_from_worker worker
        return Request.find(:first,
                  :conditions => ["worker = ?", worker] ,
                  :order => "id DESC" )
      end
    end
    
    class Run<ActiveRecord::Base
      has_many :steps
      belongs_to :request
      acts_as_reportable
    end

    class Step<ActiveRecord::Base
      belongs_to :run
      acts_as_reportable
    end
         
  end
end