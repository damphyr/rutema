#  Copyright (c) 2007-2015 Vassilis Rizopoulos. All rights reserved.

require_relative "framework"

module Rutema
  module Runners
    class Default
      include Rutema::Messaging
      attr_reader :context
      attr_accessor :setup,:teardown
      def initialize context,queue
        @setup=nil
        @teardown=nil
        @context=context || Hash.new
        @queue = queue
        @number_of_runs=0
      end

      def run spec
        state={'start_time'=>Time.now, "sequence_id"=>@number_of_runs,"test"=>spec.name}
        steps=[]
        status=:success
        message('test'=>spec.name,'phase'=>'started')
        if @setup
          message('test'=>spec.name,'phase'=>'setup')
          executed_steps,status=run_scenario("setup",@setup.scenario,@context)
          steps+=executed_steps
        end
        if status!=:error
          message('test'=>spec.name,'phase'=>'running')
          executed_steps,status=run_scenario(spec.name,spec.scenario,@context)
          steps+=executed_steps
        end
        state['status']=status
        if @teardown
          message('test'=>spec.name,'phase'=>'teardown')
          executed_steps,status=run_scenario("teardown",@teardown.scenario,@context)
        end
        message('test'=>spec.name,'phase'=>'finished')
        state["stop_time"]=Time.now
        state['steps']=steps
        @number_of_runs+=1
        return state
      end

      private
      def run_scenario name,scenario,meta
        executed_steps=[]
        status=:warning
        begin 
          stps=scenario.steps
          if stps.empty?
            error(name,"Scenario #{name} contains no steps")
            status=:error
          else
            stps.each do |s| 
              message('test'=>name,:message=>s.to_s)
              executed_steps<<run_step(s,meta)
              message('test'=>name,'number'=>s.number,'status'=>s.status,'out'=>s.output,'err'=>s.error,'duration'=>s.exec_time)
              status=s.status
              break if :error==s.status
            end
          end
        rescue  
          error(name,$!.message)
          status=:error
        end
        return executed_steps,status
      end
      def run_step step,meta
        if step.has_cmd? && step.cmd.respond_to?(:run)
          step.cmd.run(meta)
        else
          message("No command associated with step '#{step.step_type}'. Step number is #{step.number}")
        end
        step.status=:success if step.status==:error && step.ignore?
        return step
      end
    end
  end
  
  #StepRunner halts before every step and asks if it should be executed or not.
  # class StepRunner<Runner
  #   def initialize setup=nil, teardown=nil,logger=nil
  #     @questioner=HighLine.new
  #     super(setup,teardown,logger)
  #   end
  #   def run_step step
  #     if @questioner.agree("Execute #{step.to_s}?")
  #       return super(step)
  #     else
  #       msg="#{step.number} - #{step.step_type} - #{step.status}"
  #       @logger.info(msg)
  #       return step
  #     end
  #   end
  # end
end