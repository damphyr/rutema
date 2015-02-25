#  Copyright (c) 2007-2011 Vassilis Rizopoulos. All rights reserved.
module Rutema
  module Runners
    module DefaultRunner
      attr_reader :context
      attr_accessor :setup,:teardown
      def initialize context,queue
        @context=context || Hash.new
        @queue = queue
      end

      def run spec
        message('test'=>name,'phase'=>'running')
        if @setup
          run_scenario("#{name}_setup",@setup)
        end
      end

      private
      def run_scenario name,scenario
        state=Patir::CommandSequenceStatus.new(name,scenario.steps)
        begin 
          if evaluate_attention(scenario,state)
            stps=scenario.steps
            if stps.empty?
              error(name,"Scenario #{name} contains no steps")
              state.status=:warning
            else
              stps.each do |s| 
                state.step=run_step(s)
                message('test'=>name,'status'=>step.status,'number'=>step.number,'out'=>step.output,'err'=>step.error,'duration'=>step.exec_time,'step_type'=>step.step_type)
                break if :error==state.status
              end
            end
          end
        rescue  
          error(name,$!.message)
          state.status=:error
        end
        state.stop_time=Time.now
        state.sequence_id=@number_of_runs
        return state
      end
      def run_step step
        if step.has_cmd? && step.cmd.respond_to?(:run)
          step.cmd.run(@context)
          msg=step.to_s
        else
          message("No command associated with step '#{step.step_type}'. Step number is #{step.number}")
        end
        step.status=:success if step.status==:error && step.ignore?
        return step
      end
    end
  end
  #Runner executes TestScenario instances and maintains the state of all scenarios run.
  class Runner
    attr_reader :context
    attr_accessor :setup,:teardown
    attr_writer :attended

    def initialize context,queue
      @attended=false
      @context=context || Hash.new
      @queue = queue
    end
    
    #Tells you if the system runs in the mode that expects user input
    def attended?
      return @attended
    end
    #Runs a scenario and stores the result internally
    #
    #Returns the result of the run as a Patir::CommandSequenceStatus
    def run name,scenario
      #if setup /teardown is defined we need to execute them before and after
      if @setup
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
    private
    def error identifier,message
      message(:error=>{:test=>identifier,:message=>message})
      nil
    end
    def message message
      @queue.push(message)
    end
    def run_scenario name,scenario
      state=initialize_state(name,scenario)
      begin 
        if evaluate_attention(scenario,state)
          stps=scenario.steps
          if stps.empty?
            error(name,"Scenario #{name} contains no steps")
            state.status=:warning
          else
            stps.each do |s| 
              state.step=run_step(s)
              break if :error==state.status
            end
          end
        end
      rescue  
        error(name,$!.message)
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
          message("Attended scenario cannot be run in unattended mode")
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
      if step.has_cmd? && step.cmd.respond_to?(:run)
        step.cmd.run(@context)
        msg=step.to_s
      else
        message("No command associated with step '#{step.step_type}'. Step number is #{step.number}")
      end
      step.status=:success if step.status==:error && step.ignore?
      message({'status'=>step.status,'number'=>step.number,'out'=>step.output,'err'=>step.error,'duration'=>step.exec_time,'step_type'=>step.step_type})
      return step
    end
  end
end