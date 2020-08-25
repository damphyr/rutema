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
        @cleanup_blocks = []
      end

      def run spec, is_special = false
        begin
          @context["spec_name"]=spec.name
          steps=[]
          status=:success
          state={'start_time'=>Time.now, "sequence_id"=>@number_of_runs,:test=>spec.name}
          message(:test=>spec.name,:text=>'started')
          if @setup
            message(:test=>spec.name,:text=>'setup')
            executed_steps,setup_status=run_scenario("_setup_",@setup.scenario,@context,true)
            status=setup_status unless STATUS_CODES.find_index(setup_status) < STATUS_CODES.find_index(status)
            steps+=executed_steps
          end
          if status!=:error
            message(:test=>spec.name,:text=>'running')
            executed_steps,testspec_status=run_scenario(spec.name,spec.scenario,@context,is_special)
            status=testspec_status unless STATUS_CODES.find_index(testspec_status) < STATUS_CODES.find_index(status)
            steps+=executed_steps
          else
            message(:test=>spec.name,'number'=>0,'status'=>:error,'out'=>"Setup failed",'err'=>"",'duration'=>0)
          end
          @context['rutema_status']=status
          if @teardown
            message(:test=>spec.name,:text=>'teardown')
            executed_steps,teardown_status=run_scenario("_teardown_",@teardown.scenario,@context,true)
            status=teardown_status unless STATUS_CODES.find_index(teardown_status) < STATUS_CODES.find_index(status)
          end
          @context['rutema_status']=status
          message(:test=>spec.name,:text=>'finished')
          state['status']=status
          state["stop_time"]=Time.now
          state['steps']=steps
          @number_of_runs+=1
          return state
        ensure
          begin
            cleanup_exception = nil
            @cleanup_blocks.each do |cleanup_block|
              #Try all bocks
              begin
                cleanup_block.run(@context) if cleanup_block.respond_to?(:run)
              rescue Exception => e
                #Ignore errors, ensure all cleanup steps are attempted
                cleanup_exception = e
              end              
            end
            raise cleanup_exception if !cleanup_exception.nil?
          ensure
            @cleanup_blocks = []
          end
        end
      end

      private
      def run_scenario name,scenario,meta,is_special
        executed_steps=[]
        status=:skipped
        begin 
          stps=scenario.steps
          if stps.empty?
            error(name,"Scenario #{name} contains no steps")
            status=:error
          else
            stps.each do |s|

              if status == :error && s.skip_on_error?
                message(:test=>name,:text=>s.to_s,'number'=>s.number,'status'=>:skipped,'is_special'=>is_special)
              else
                message(:test=>name,:text=>s.to_s,'number'=>s.number,'status'=>:started,'is_special'=>is_special)
                sleep 0.05
                begin
                  cache_cleanup(s)
                  executed_steps<<run_step(s,meta)
                rescue Exception => e
                  throw e unless s.continue?
                  s.status = :error                
                end
                message(:test=>name,:text=>s.to_s,'number'=>s.number,'status'=>s.status,'out'=>s.output,'err'=>s.error,'backtrace'=>s.backtrace,'duration'=>s.exec_time,'is_special'=>is_special)
                status=s.status unless STATUS_CODES.find_index(s.status) < STATUS_CODES.find_index(status)
                break if :error==s.status and !s.continue?
              end
            end
          end
        rescue
          error(name,$!.message)
          status=:error
        end
        return executed_steps,status
      end
      def cache_cleanup step
        if step.has_cleanup? && step.cleanup.respond_to?(:run)
          @cleanup_blocks << step.cleanup
        end
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