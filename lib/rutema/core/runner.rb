# Copyright (c) 2007-2020 Vassilis Rizopoulos. All rights reserved.

# frozen_string_literal: true

require 'English'

require_relative 'framework'

module Rutema
  ##
  # Module for the definition of runners which can be used by Rutema::Engine to
  # execute test specifications
  #
  # _rutema_ comes by default with two runners Rutema::Runners::Default and
  # Rutema::Runners::NoOp
  module Runners
    ##
    # An empty base class for all runner classes
    class BaseRunner
    end

    ##
    # Rutema::Runners::Default is the default runner used by Rutema::Engine
    #
    # As its name indicates its purpose is to run (i.e. execute) test
    # specifications which is done through its #run method.
    class Default < BaseRunner
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
        @context['spec_name'] = spec.name
        steps = []
        status = :success
        state = { 'sequence_id' => @number_of_runs, 'start_time' => Time.now, test: spec.name }
        message(test: spec.name, text: 'started')
        if @setup
          message(test: spec.name, text: 'setup')
          executed_steps, setup_status = run_scenario('_setup_', @setup.scenario,
                                                      @context, true)
          status = setup_status unless STATUS_CODES.find_index(setup_status) < STATUS_CODES.find_index(status)
          steps += executed_steps
        end
        if status != :error
          message(test: spec.name, text: 'running')
          executed_steps, testspec_status = run_scenario(spec.name, spec.scenario,
                                                         @context, is_special)
          status = testspec_status unless STATUS_CODES.find_index(testspec_status) < STATUS_CODES.find_index(status)
          steps += executed_steps
        else
          message(test: spec.name, 'duration' => 0, 'err' => '', 'number' => 0,
                  'out' => 'Setup failed', 'status' => :error)
        end
        @context['rutema_status'] = status
        if @teardown
          message(test: spec.name, text: 'teardown')
          _, teardown_status = run_scenario('_teardown_', @teardown.scenario,
                                            @context, true)
          status = teardown_status unless STATUS_CODES.find_index(teardown_status) < STATUS_CODES.find_index(status)
        end
        @context['rutema_status'] = status
        message(test: spec.name, text: 'finished')
        state['status'] = status
        state['stop_time'] = Time.now
        state['steps'] = steps
        @number_of_runs += 1
        state
      end

      private

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
              message(test: name, text: s.to_s, 'number' => s.number,
                      'status' => :started, 'is_special' => is_special)
              sleep 0.05
              begin
                executed_steps << run_step(s, meta)
                message(test: name, text: s.to_s, 'number' => s.number,
                        'status' => s.status, 'out' => s.output, 'err' => s.error,
                        'backtrace' => s.backtrace, 'duration' => s.exec_time,
                        'is_special' => is_special)
              rescue Exception => e
                throw e unless s.continue?
                s.status = :error
              end
              # Status of lower "importance" my not cover higher importance ones
              status = s.status unless STATUS_CODES.find_index(s.status) < STATUS_CODES.find_index(status)
              break if s.status == :error && !s.continue?
            end
          end
        rescue StandardError
          error(name, $ERROR_INFO.message)
          status = :error
        end
        [executed_steps, status]
      end

      def run_step(step, meta)
        if step.has_cmd? && step.cmd.respond_to?(:run)
          step.cmd.run(meta)
        else
          message("No command associated with step '#{step.step_type}'. Step number is #{step.number}")
          step.status = :warning
        end
        step.status = :success if step.ignore?
        step
      end
    end

    ##
    # Rutema::Runners::NoOp overrides the #run_step method to make it
    # non-operational
    class NoOp < Default
      def run_step(step, _meta)
        unless step.has_cmd? && step.cmd.respond_to?(:run)
          message("No command associated with step '#{step.step_type}'. Step number is #{step.number}")
          step.status = :warning
        end
        step.status = :success if step.ignore?
        step
      end
    end
  end
end
