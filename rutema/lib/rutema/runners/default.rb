#  Copyright (c) 2007-2011 Vassilis Rizopoulos. All rights reserved.
$:.unshift File.join(File.dirname(__FILE__),'..','..')

module Rutema
  #Runner executes TestScenario instances and maintains the state of all scenarios run.
  class Runner
    attr_reader :states,:number_of_runs,:context
    attr_accessor :setup,:teardown
    attr_writer :attended

    #setup and teardown are TestScenario instances that will run before and after each call
    #to the scenario.
    def initialize context=nil,setup=nil, teardown=nil,logger=nil
      @setup=setup
      @teardown=teardown
      @attended=false
      @logger=logger
      @logger||=Patir.setup_logger
      @states=Hash.new
      @number_of_runs=0
      @context=context || Hash.new
    end
    
    #Tells you if the system runs in the mode that expects user input
    def attended?
      return @attended
    end
    #Runs a scenario and stores the result internally
    #
    #Returns the result of the run as a Patir::CommandSequenceStatus
    def run name,scenario, run_setup=true
      @logger.debug("Starting run for #{name} with #{scenario.inspect}")
      @context[:scenario_name]=name
      #if setup /teardown is defined we need to execute them before and after
      if @setup && run_setup
        @logger.info("Setup for #{name}")
        @states["#{name}_setup"]=run_scenario("#{name}_setup",@setup)
        @states["#{name}_setup"].sequence_id="s#{@number_of_runs}"
        if @states["#{name}_setup"].executed? 
          #do not execute the scenario unless the setup was succesful
          if @states["#{name}_setup"].success?
            @logger.info("Scenario for #{name}")
            @states[name]=run_scenario(name,scenario)
            @states[name].sequence_id="#{@number_of_runs}"
          else
            @states[name]=initialize_state(name,scenario)
            @states[name].sequence_id="#{@number_of_runs}"
          end
        end
      else
        @logger.info("Scenario for #{name}")
        @states[name]=run_scenario(name,scenario)
        @states[name].sequence_id="#{@number_of_runs}"
      end
      #no setup means no teardown
      if @teardown && run_setup
        #always execute teardown
        @logger.warn("Teardown for #{name}")
        @states["#{name}_teardown"]=run_scenario("#{name}_teardown",@teardown)
        @states["#{name}_teardown"].sequence_id="#{@number_of_runs}t"
      end
      @number_of_runs+=1
      @context[:scenario_name]=nil
      return @states[name]
    end
    
    #Returns the state of the scenario with the given name.
    #
    #Will return nil if no scenario is found under that name.
    def [](name)
      return @states[name]
    end
    
    #Resets the Runner's internal state
    def reset
      @states.clear
      @number_of_runs=0
    end

    #returns true if all the scenarios in the last run were succesful or if nothing was run yet
    def success?
      @success=true
      @states.each  do |k,v|
        @success&=(v.status!=:error)
      end
      return @success
    end
    private
    def run_scenario name,scenario
      state=initialize_state(name,scenario)
      begin 
        if evaluate_attention(scenario,state)
          stps=scenario.steps
          if stps.empty?
            @logger.warn("Scenario #{name} contains no steps")
            state.status=:warning
          else
            stps.each do |s| 
              state.step=run_step(s)
              break if :error==state.status
            end
          end
        end
      rescue  
        @logger.error("Encountered error in #{name}: #{$!.message}")
        @logger.debug($!)
        state.status=:error
      end
      state.stop_time=Time.now
      state.sequence_id=@number_of_runs
      return state
    end
    def initialize_state name,scenario
      state=Patir::CommandSequenceStatus.new(name,scenario.steps)
    end
    def evaluate_attention scenario,state
      if scenario.attended?
        if !self.attended?
          @logger.warn("Attended scenario cannot be run in unattended mode")
          state.status=:warning
          return false
        end
        state.strategy=:attended
      else
        state.strategy=:unattended
      end
      return true
    end
    def run_step step
      @logger.info("Running step #{step.number} - #{step.name}")
      if step.has_cmd? && step.cmd.respond_to?(:run)
        step.cmd.run(@context)
        msg=step.to_s
        if !step.cmd.success?
          msg<<"\n#{step.cmd.output}" unless step.cmd.output.empty?
          msg<<"\n#{step.cmd.error}" unless step.cmd.error.empty?
        end
      else
        @logger.warn("No command associated with step '#{step.step_type}'. Step number is #{step.number}")
      end
      step.status=:success if step.status==:error && step.ignore?
      log_step_result(step,msg)
      return step
    end
    def log_step_result step,msg
      if step.status==:error
        if step.ignore?
          @logger.warn("Step failed but result is being ignored!\n#{msg}")
        else
          @logger.error(msg) 
        end
      else
        @logger.info(msg) if msg && !msg.empty?
      end
    end
  end
end