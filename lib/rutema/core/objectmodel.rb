# Copyright (c) 2007-2020 Vassilis Rizopoulos. All rights reserved.
require 'patir/command'

module Rutema
  ##
  # This module adds functionality that allows to arbitrarily add attributes to
  # a class and then have the accessor methods for these attributes
  # automagically appear.
  module SpecificationElement
    ##
    # Adds an attribute with the given +value+ to the class. +symbol+ can be a
    # Symbol or a String, the rest are silently ignored
    def attribute(symbol, value)
      @attributes ||= {}
      case symbol
      when String then @attributes[:"#{symbol}"] = value
      when Symbol then @attributes[symbol] = value
      end
    end

    ##
    # Allows to call +object.attribute+, +object.attribute=+, +object.attribute?+
    # and +object.has_attribute?+
    #
    # +object.attribute+ and +object.attribute?+ will throw +NoMethodError+ if
    # attribute is not set.
    #
    # +object.attribute=+ will set the value of the attribute to the right
    # operand.
    def method_missing(symbol, *args)
      @attributes ||= {}
      key = symbol.id2name.chomp('?').chomp('=').sub(/^has_/, '')
      @attributes[:"#{key}"] = args[0] if key + '=' == symbol.id2name
      if @attributes.key?(:"#{key}")
        return true if 'has_' + key + '?' == symbol.id2name

        @attributes[:"#{key}"]
      else
        return false if 'has_' + key + '?' == symbol.id2name

        super(symbol, *args)
      end
    end

    ##
    # Refer to (Ruby-Doc.org)[https://ruby-doc.org/core-2.7.1/Object.html#method-i-respond_to-3F]
    def respond_to?(symbol, include_all = false)
      @attributes ||= {}
      key = symbol.id2name.chomp('?').chomp('=').sub(/^has_/, '')
      if @attributes.key?(:"#{key}")
        true
      else
        super(symbol, include_all)
      end
    end
  end

  ##
  # A Rutema::Specification contains all elements required for running a test:
  # the builds used, the scenario to run together with a textual description and
  # information that aids in tracing the test back to the requirements.
  class Specification
    include SpecificationElement
    attr_accessor :scenario

    ##
    # Initialize by a +Hash+ of parameters
    #
    # Following keys have a meaning for initialization:
    # * +:name+ - the name of the testcase. Should uniquely identify the testcase
    # * +:title+ - a one liner describing what the testcase does
    # * +:filename+ - the filename describing the testcase
    # * +:description+ - a full textual description for the testcase. To be used in reports and documents
    # * +:scenario+ - An instance of Rutema::Scenario
    # * +:version+ - The version of this specification
    #
    # Default values are empty +Array+ and +String+ instances (_scenario_ is
    # +nil+ and _version_ does not exist)
    def initialize(params)
      @attributes = params if params
      @attributes ||= {}
      @attributes[:description] ||= ''
      @attributes[:filename] ||= ''
      @attributes[:name] ||= ''
      @attributes[:title] ||= ''
      @scenario = @attributes[:scenario]
    end

    def to_s #:nodoc:
      "#{@attributes[:name]} - #{@attributes[:title]}"
    end
  end

  ##
  # A Rutema::Scenario is a sequence of Rutema::Step instances.
  #
  # Rutema::Step instances are run in the defined sequence and the scenario is
  # successful if all steps are conducted succesfully.
  #
  # From the execution point of view each step is either successful or failed.
  # This depends on the exit code of each step's command.
  #
  # Failure in a step results in the interruption of execution and a report of
  # occurred errors.
  class Scenario
    include SpecificationElement
    attr_accessor :steps

    ##
    # Initialize the Rutema::Scenario by an array of Rutema::Step instances
    def initialize(steps)
      @attributes = {}
      @steps = steps
      @steps ||= []
    end

    ##
    # Adds a Rutema::Step instance to the end of the steps sequence
    def add_step(step)
      @steps << step
    end
  end

  ##
  # This class represents a step in a Rutema::Scenario
  #
  # Each Rutema::Step can have text and a command associated with it.
  #
  # Rutema::Step standard attributes are:
  # * +attended+ - the step can only run in attended mode - it requires user
  #   input.
  # * +step_type+ - a string identifying the type of the step. By default it's
  #   "step".
  # * +ignore+ - set to true if the step's success or failure is to be ignored.
  #   It essentially means that the step is always considered to be succesfully
  #   conducted.
  # * +number+ - this is set when the step is assigned to a Rutema::Scenario and
  #   is the sequence number
  # * +cmd+ - the command associated with this step. This should quack like
  #   Patir::Command.
  # * +status+ - one of +:not_executed+, +:success+, +:warning+, +:error+.
  #   Encapsulates the underlying command's status
  #
  #
  # == Dynamic behaviour
  #
  # A Rutema::Step can be queried dynamically about the attributes it posesses
  # with e.g. +step.has_script?+. This will return +true+ if +script+ is an
  # attribute of +step+. Attributes are mostly assigned by the parser, i.e. the
  # Rutema::Parsers::XML, from an XML element.
  #
  # <test script="some_script"/> will create a Rutema::Step instance with
  # step_type == 'test' and script == 'some_script'. In this case
  # +step.has_script?+ returns +true+ and +step.script+ returns 'some_script'.
  #
  # Just like an +OpenStruct+ Rutema::Step attributes will be created by direct
  # assignment. step.script = 'some_script' creates the +script+ attribute if it
  # does not already exist.
  #
  # See Rutema::SpecificationElement for the implementation details.
  class Step
    include SpecificationElement
    include Patir::Command

    # The +txt+ argument describes the step, +cmd+ is the command which shall be run
    def initialize(txt = '', cmd = nil)
      @attributes = {}
      # ignore is off by default
      @attributes[:ignore] = false
      # assign
      @attributes[:cmd] = cmd if cmd
      @attributes[:text] = txt
      @number = 0
      @attributes[:step_type] = 'step'
    end

    def name
      name_with_parameters
    end

    def output
      return '' unless @attributes[:cmd]

      @attributes[:cmd].output
    end

    def error
      return 'no command associated' unless @attributes[:cmd]

      @attributes[:cmd].error
    end

    def backtrace
      return "no command associated" unless @attributes[:cmd]
      return @attributes[:cmd].backtrace
    end

    def ignore?
      return false unless @attributes[:ignore]

      @attributes[:ignore]
    end

    def exec_time
      return 0 unless @attributes[:cmd]

      @attributes[:cmd].exec_time
    end

    def status
      return :warning unless @attributes[:cmd]

      @attributes[:cmd].status
    end

    def status=(new_state)
      @attributes[:cmd].status = new_state if @attributes[:cmd]
    end

    def run(context = nil)
      return not_executed unless @attributes[:cmd]

      @attributes[:cmd].run(context)
    end

    def reset
      @attributes[:cmd]&.reset
    end

    def name_with_parameters
      param = " - #{cmd}" if has_cmd?
      "#{@attributes[:step_type]}#{param}"
    end

    def to_s #:nodoc:
      msg = if has_cmd?
              "#{number} - #{cmd}"
            else
              "#{number} - #{name}"
            end
      msg << " in #{included_in}" if has_included_in?
      msg
    end
  end
end

class Patir::ShellCommand
  def to_s #:nodoc:
    @command
  end
end

class Patir::RubyCommand
  def to_s #:nodoc:
    @name
  end
end
