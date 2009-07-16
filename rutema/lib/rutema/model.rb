#  Copyright (c) 2007 Vassilis Rizopoulos. All rights reserved.
$:.unshift File.join(File.dirname(__FILE__),"..")
require 'active_record'
require 'ruport/acts_as_reportable'
#this fixes the AR Logger hack that annoys me sooooo much
class Logger
  private
  def format_message(severity, datetime, progname, msg)
    (@formatter || @default_formatter).call(severity, datetime, progname, msg)
  end
end
module Rutema 
  #This is the ActiveRecord model for Rutema:
  #
  #A Run has n instances of executed scenarios - which in turn have n instances of executed steps - 
  #and n instances of parse errors.
  module Model
    #This is the schema for the AR database used to store test results
    #
    #We store the RutemaConfiguration#context for every run so that reports for past runs can be recreated without running the actual tests again.
    class Schema<ActiveRecord::Migration
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

    class Run<ActiveRecord::Base
      has_many :scenarios
      has_many :parse_errors
      serialize :context
      acts_as_reportable      
    end

    class Scenario<ActiveRecord::Base
      belongs_to :run
      has_many :steps
      acts_as_reportable
    end

    class Step<ActiveRecord::Base
      belongs_to :scenario
      acts_as_reportable
    end

    class ParseError<ActiveRecord::Base
      belongs_to :run
      acts_as_reportable
    end
  
    class UpgradeV9toV10<ActiveRecord::Migration
      def self.up
        puts("Adding new columns")
        add_column(:scenarios, :title, :string,{:default=>"title"})
        add_column(:scenarios, :description, :string,{:default=>"description"})
        puts("Updating existing scenario entries")
        Rutema::Model::Scenario.find(:all).each do |sc|
          puts "Updating scenario #{sc.id}"
          sc.title="#{name}"
          sc.description="#{name}"
        end
      end
    end
  end
end