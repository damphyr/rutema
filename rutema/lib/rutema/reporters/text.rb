module Rutema
  #This reporter cerates a simple text summary of a test run
  class TextReporter
    def initialize params=nil 
    end
    
    #Returns the text summary
    #
    #runner_states is an Array of Patir::CommandSequenceStatus containing the stati of the last run (so it contains all the Scenario stati for the loaded tests)
    #
    #parse_errors is an Array of {:filename,:error} hashes containing the errors encountered by the parser when loading the specifications
    def report specifications,runner_states,parse_errors,configuration
      return text_report(specifications,runner_states,parse_errors)
    end
    private
    def text_report specifications,runner_states,parse_errors
      msg=""
      #Report on parse errors
      msg<<"No parse errors" if parse_errors.empty?
      msg<<"One parse error:" if parse_errors.size==1
      msg<<"#{parse_errors.size} parse errors:" if parse_errors.size>1
      parse_errors.each do |er|
        msg<<"\n\tin #{er[:filename]} : #{er[:error]}"
      end
      msg<<"\n---"
      #Report on scenarios
      runner_states.compact!#make sure no nil elements make it through
      msg<<"\nNo scenarios in this run" if runner_states.empty?
      msg<<"\nOne scenario in the current run" if runner_states.size==1
      msg<<"\n#{runner_states.size} scenarios in the current run" if runner_states.size>1
      not_run = runner_states.select{|state| state.status == :not_executed }.sort_by {|state| state.sequence_id.to_i}
      errors = runner_states.select{|state| state.status == :error }.sort_by {|state| state.sequence_id.to_i}
      warnings = runner_states.select{|state| state.status == :warning }.sort_by {|state| state.sequence_id.to_i}
      successes = runner_states.select{|state| state.status == :success }.sort_by {|state| state.sequence_id.to_i}
      msg<<"\n#{errors.size} errors, #{warnings.size} warnings, #{successes.size} successes"
      msg<<"\nErrors:" unless errors.empty?
      msg<<scenario_summaries(errors,specifications)
      msg<<"\nWarnings:" unless warnings.empty?
      msg<<scenario_summaries(warnings,specifications)
      msg<<"\nNot executed:" unless not_run.empty?
      not_run.each do |state|
        msg<<"\n#{specifications[state.sequence_name].title}" if specifications[state.sequence_name]
      end
      msg<<"\nSuccesses:" unless successes.empty?
      msg<<scenario_summaries(successes,specifications)
      
      return msg
    end
    
    def scenario_summaries scenarios,specifications
      msg=""
      unless scenarios.empty?
        scenarios.each do |state|
          msg<<"\n#{specifications[state.sequence_name].title}" if specifications[state.sequence_name]
          msg<<"\n#{state.summary}\n---"
        end
      end
      return msg
    end
  end
end