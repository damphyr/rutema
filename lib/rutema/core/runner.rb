#  Copyright (c) 2007-2017 Vassilis Rizopoulos. All rights reserved.

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
        steps=[]
        status=:success
        state={'start_time'=>Time.now, "sequence_id"=>@number_of_runs,:test=>spec.name}
        message(:test=>spec.name,:text=>'started')
        if @setup
          message(:test=>spec.name,:text=>'setup')
          executed_steps,status=run_scenario("_setup_",@setup.scenario,@context)
          steps+=executed_steps
        end
        if status!=:error
          message(:test=>spec.name,:text=>'running')
          executed_steps,status=run_scenario(spec.name,spec.scenario,@context)
          steps+=executed_steps
        else
          message(:test=>spec.name,'number'=>0,'status'=>:error,'out'=>"Setup failed",'err'=>"",'duration'=>0)
        end
        state['status']=status
        if @teardown
          message(:test=>spec.name,:text=>'teardown')
          executed_steps,status=run_scenario("_teardown_",@teardown.scenario,@context)
        end
        message(:test=>spec.name,:text=>'finished')
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
              executed_steps<<run_step(s,meta)
              message(:test=>name,:text=>s.to_s,'number'=>s.number,'status'=>s.status,'out'=>s.output,'err'=>s.error,'duration'=>s.exec_time)
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
          step.status=:warning
        end
        step.status=:success if step.ignore?
        return step
      end
    end

    class NoOp<Default
      def run_step step,meta
        unless step.has_cmd? && step.cmd.respond_to?(:run)
          message("No command associated with step '#{step.step_type}'. Step number is #{step.number}")
          step.status=:warning
        end
        step.status=:success if step.ignore?
        return step
      end
    end
  end
end