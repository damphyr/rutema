#  Copyright (c) 2008 Vassilis Rizopoulos. All rights reserved.
$:.unshift File.join(File.dirname(__FILE__),"..")
require 'rutemaweb/gems'


module Rutema

  module Model
    #Extensions of Run to accomodate specific view requirements for rutemaweb
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
        self.scenarios.select{|sc| !sc.success? && sc.is_test? }.size
      end
      #returns the number of actual tests (so, don't take into account setup or teardown tests)
      def number_of_tests
         self.scenarios.select{|sc| sc.is_test? }.size
      end
      def config_file
        return nil if self.context.is_a?(OpenStruct)
        return context[:config_file]
      end
    end
    
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
    end
  end
end




