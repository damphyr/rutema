#  Copyright (c) 2007-2021 Vassilis Rizopoulos. All rights reserved.

require_relative "framework"

module Rutema
  module Runners
    # The default test runner
    class Default
      include Rutema::Messaging

      attr_reader :context
      attr_accessor :setup, :teardown

      def initialize(context, queue)
        @setup = nil
        @teardown = nil
        @context = context || {}
        @queue = queue
        @number_of_runs = 0
        @cleanup_blocks = []
      end

      def run(spec, is_special = false)
        @context["spec_name"] = spec.name
        steps = []
        run_status = :success
        state = { "start_time" => Time.now, "sequence_id" => @number_of_runs, :test => spec.name }
        message(:test => spec.name, :text => "started")
        if @setup
          message(:test => spec.name, :text => "setup")
          run_status, steps = execute_and_collect_state("_setup_", @setup.scenario, true, run_status, steps)
        end
        if run_status == :error
          message(:test => spec.name, "number" => 0, "status" => :error, "out" => "Setup failed", "err" => "", "duration" => 0)
        else
          message(:test => spec.name, :text => "running")
          run_status, steps = execute_and_collect_state(spec.name, spec.scenario, is_special, run_status, steps)
        end
        @context["rutema_status"] = run_status
        if @teardown
          message(:test => spec.name, :text => "teardown")
          run_status, steps = execute_and_collect_state("_teardown_", @teardown.scenario, true, run_status, steps)
        end
        wrap_up_execution(run_status, steps, spec, state)
      ensure
        ensure_cleanup_on_exception
      end

      private

      def execute_and_collect_state(test_name, scenario, is_special, current_run_status, steps_until_now)
        executed_steps, scenario_status = run_scenario(test_name, scenario, @context, is_special)
        current_run_status = scenario_status unless STATUS_CODES.find_index(scenario_status) < STATUS_CODES.find_index(current_run_status)
        steps_until_now += executed_steps
        return current_run_status, steps_until_now
      end

      def wrap_up_execution(run_status, executed_steps, last_run_spec, state)
        @context["rutema_status"] = run_status
        message(:test => last_run_spec.name, :text => "finished")
        state["status"] = run_status
        state["stop_time"] = Time.now
        state["steps"] = executed_steps
        @number_of_runs += 1
        return state
      end

      def ensure_cleanup_on_exception
        cleanup_exception = nil
        @cleanup_blocks.each do |cleanup_block|
          # Try all blocks

          cleanup_block.run(@context) if cleanup_block.respond_to?(:run)
        # rubocop:disable Lint/RescueException
        rescue Exception => e
          # Ignore errors, ensure all cleanup steps are attempted
          cleanup_exception = e
        end
        # rubocop:enable Lint/RescueException
        raise cleanup_exception unless cleanup_exception.nil?
      ensure
        @cleanup_blocks = []
      end

      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def run_scenario(name, scenario, meta, is_special)
        executed_steps = []
        status = :skipped
        begin
          stps = scenario.steps
          if stps.empty?
            error(name, "Scenario #{name} contains no steps")
            status = :error
          else
            stps.each do |s|
              if status == :error && s.skip_on_error?
                message(:test => name, :text => s.to_s, "number" => s.number, "status" => :skipped, "is_special" => is_special)
              else
                executed_step = next_step(s, name, meta, is_special)
                status = executed_step.status unless STATUS_CODES.find_index(executed_step.status) < STATUS_CODES.find_index(status)
                executed_steps << executed_step
                break if s.status == :error && !s.continue?
              end
            end
          end
        rescue StandardError
          error(name, "#{$!.message}\n#{$!.backtrace.join("\n")}")
          status = :error
        end
        return executed_steps, status
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      def next_step(step_spec, test_name, meta, test_is_special)
        message(
          :test => test_name, :text => step_spec.to_s, "number" => step_spec.number,
          "status" => :started, "is_special" => test_is_special
        )
        sleep 0.05
        begin
          cache_cleanup(step_spec)
          executed_step = run_step(step_spec, meta)
          # rubocop:disable Lint/RescueException
        rescue Exception => e
          throw e unless step_spec.continue?
          step_spec.status = :error
          # rubocop:enable Lint/RescueException
        end
        message(
          :test => test_name, :text => step_spec.to_s, "number" => step_spec.number,
          "status" => step_spec.status, "out" => step_spec.output, "err" => step_spec.error,
          "backtrace" => step_spec.backtrace, "duration" => step_spec.exec_time,
          "is_special" => test_is_special
        )
        return executed_step
      end

      def cache_cleanup(step)
        return unless step.has_cleanup? && step.cleanup.respond_to?(:run)

        @cleanup_blocks << step.cleanup
      end

      def run_step(step, meta)
        if step.has_cmd? && step.cmd.respond_to?(:run)
          step.cmd.run(meta)
        else
          message("No command associated with step '#{step.step_type}'. Step number is #{step.number}")
          step.status = :warning
        end
        step.status = :success if step.ignore?
        return step
      end
    end

    ##
    # Fake runner which does not run the passed steps but just sets their
    # execution status to +:success+
    #
    # Steps that do not respond to +:run+ have their status set to +:warning+.
    #
    # Returns the step after "executing" it successfully
    class NoOp < Default
      ##
      # Simulate running the step by setting its status to +:success+
      #
      # If the step does not respond to +:run+ then +:warning+ is set as its
      # status.
      #
      # * +step+ -
      def run_step(step, _meta)
        unless step.has_cmd? && step.cmd.respond_to?(:run)
          message("No command associated with step '#{step.step_type}'. Step number is #{step.number}")
          step.status = :warning
        end
        step.status = :success if step.ignore?
        return step
      end
    end
  end
end
