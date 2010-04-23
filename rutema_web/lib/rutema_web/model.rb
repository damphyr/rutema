#  Copyright (c) 2008 Vassilis Rizopoulos. All rights reserved.
$:.unshift File.join(File.dirname(__FILE__),"..") 
require 'rutema/model'
module Rutema
  module Model
    #Extensions of Rutema::Model::Run to accomodate specific view requirements for rutema_web
    class Run <ActiveRecord::Base
      # The view wants to display runs grouped into pages, 
      # where each page shows page_size runs at a time. 
      # This method returns the runs on page page_num (starting 
      # at zero). 
      def self.find_on_page(page_num, page_size,conditions=nil) 
        find(:all, 
        :order => "id DESC", 
        :limit => page_size, 
        :conditions=>conditions,
        :offset => page_num*page_size) 
      end
      
      def status
        st=:success
        st=:warning if scenarios.empty?
        self.scenarios.each do |sc|
          case sc.status
          when "warning" || "not_executed"
            st=:warning unless st==:error
            break
          when "error"
            st=:error
            break
          end
        end
        return st
      end
      #number of unsuccessful scenarios (does not count setup or teardown scripts)
      def number_of_failed
        #self.scenarios.select{|sc| !sc.success? && !sc.not_executed? && sc.is_test? }.size
        Rutema::Model::Scenario.count(:conditions=>"run_id=#{self.id} AND status = 'error' AND name NOT LIKE '%_teardown' AND name NOT LIKE '%_setup'")
      end
      #number of scenarios that did not run (does not count setup or teardown scripts)
      def number_of_not_executed
        #self.scenarios.select{|sc| sc.not_executed? && sc.is_test? }.size
        Rutema::Model::Scenario.count(:conditions=>"run_id=#{self.id} AND status = 'not_executed' AND name NOT LIKE '%_teardown' AND name NOT LIKE '%_setup'")
      end
      #returns the number of actual tests (so, don't take into account setup or teardown tests)
      def number_of_tests
         Rutema::Model::Scenario.count(:conditions=>"run_id=#{self.id} AND name NOT LIKE '%_teardown' AND name NOT LIKE '%_setup'")
      end
      #the number of the configuration file used to run the test
      def config_file
        return nil if self.context.is_a?(OpenStruct)
        return context[:config_file]
      end
   
    end
    #Extensions of Rutema::Model::Scenario to accomodate specific view requirements for rutema_web
    class Scenario <ActiveRecord::Base
      # The view wants to display scenarios grouped into pages, 
      # where each page shows page_size scenarios at a time. 
      # This method returns the scenarios grouped by name on page page_num (starting 
      # at zero). 
      def self.find_on_page(page_num, page_size,conditions=nil) 
        find(:all, 
        :order => "name ASC",
        :group=>"name", 
        :limit => page_size, 
        :conditions=>conditions,
        :offset => page_num*page_size) 
      end
      #returns true if the scenario does not belong to a setup or teardown script
      def is_test?
        return !(self.name=~/_setup$/ || self.name=~/_teardown$/)
      end
      def success?
        return self.status=="success"
      end
      def not_executed?
        return self.status=="not_executed"
      end
      def fail?
        return self.status=="error"
      end
    end
  end
end




