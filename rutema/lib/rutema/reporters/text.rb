module Rutema
  #This reporter creates a simple text summary of a test run
  #
  #The following configuration keys are used by TextReporter:
  #
  #:verbose - when true, the report contains info on setup and teardown specs. Optional. Default is false
  class TextReporter
    def initialize params=nil
      @verbose=params[:verbose] if params
      @verbose||=false 
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
      if @verbose
        states=runner_states
      else
        states=runner_states.select{|state| state.sequence_name !~ /[_setup|_teardown]$/}
      end
      msg<<"\nOne scenario in the current run" if states.size==1
      msg<<"\n#{states.size} scenarios in the current run" if states.size>1
      
      not_run = states.select{|state| state.status == :not_executed }.sort_by {|state| state.sequence_id.to_i}
      errors = states.select{|state| state.status == :error }.sort_by {|state| state.sequence_id.to_i}
      warnings = states.select{|state| state.status == :warning }.sort_by {|state| state.sequence_id.to_i}
      successes = states.select{|state| state.status == :success }.sort_by {|state| state.sequence_id.to_i}
      msg<<"\n#{errors.size} errors, #{warnings.size} warnings, #{successes.size} successes, #{not_run.size} not executed (setup failure)"
      msg<<"\nErrors:" unless errors.empty?
      msg<<scenario_summaries(errors,specifications)
      msg<<"\nWarnings:" unless warnings.empty?
      msg<<scenario_summaries(warnings,specifications)
      msg<<"\nNot executed:" unless not_run.empty?
      not_run.each do |state|
        if specifications[state.sequence_name]
          msg<<"\n#{specifications[state.sequence_name].title}"
        else
           msg<<"\n#{state.sequence_name}"
        end
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