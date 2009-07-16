#  Copyright (c) 2007 Vassilis Rizopoulos. All rights reserved.
$:.unshift File.join(File.dirname(__FILE__),"..")
require 'rutema/specification'

module Rutema
  #Reporter is meant as a base class for reporter classes.
  class Reporter
    #params should be a Hash containing the parameters used to initialize the class
    def initialize params
    end

    #Coordinator will pass the Rutema __configuration__ giving you access to the context which can contain data like headings and build numbers to use in the report. It will also pass the specifications used in the last run so that data like the title and the specification version can be used.
    #
    #runner_states is an Array of Patir::CommandSequenceStatus containing the stati of the last run (so it contains all the Scenario stati for the loaded tests)
    #
    #parse_errors is an Array of {:filename,:error} hashes containing the errors encountered by the parser when loading the specifications
    def report specifications,runner_states,parse_errors,configuration

    end
  end

  private
  
end