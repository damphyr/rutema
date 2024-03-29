#  Copyright (c) 2007-2021 Vassilis Rizopoulos. All rights reserved.

require 'patir/command'

module Rutema
  ##
  # Mix-in module allowing to add attributes to a class on the go
  #
  # This allows to add attributes to classes on the go and makes the accessor
  # methods appear automatically too.
  #
  # It will add a #has_attribute? method too to query if an attribute is part of
  # the object or not.
  module SpecificationElement
    ##
    # Add an attribute with a given value to the class instance
    #
    # * +symbol+ - a symbol or a string (which will be converted to a symbol
    #   internally) which shall be the name of the new attribute
    # * +value+ - the initial value of the attribute
    #
    # If +symbol+ is neither a string nor a symbol this method will be a no-op.
    def attribute symbol,value
      @attributes||=Hash.new
      case symbol
        when String then @attributes[:"#{symbol}"]=value
        when Symbol then @attributes[symbol]=value
      end
    end

    ##
    # Method enabling to call object.attribute, object.attribute=, object.attribute? and object.has_attribute?
    #
    # object.attribute and object.attribute? will throw NoMethodError if the
    # attribute is not set on the object instance.
    #
    # object.attribute= will set the attribute to the right operand and
    # object.has_attribute? will return +true+ or +false+ according to the
    # existence of the attribute.
    def method_missing symbol,*args
      @attributes||=Hash.new
      key=symbol.id2name.chomp('?').chomp('=').sub(/^has_/,"")
      @attributes[:"#{key}"]=args[0] if key+"="==symbol.id2name
      if @attributes.has_key?(:"#{key}")
          return true if "has_"+key+"?"==symbol.id2name
          return @attributes[:"#{key}"]
      else
        return false if "has_"+key+"?"==symbol.id2name
        super(symbol,*args)
      end
    end

    ##
    # Return +true+ if the object responds to the given method or else +false+
    def respond_to? symbol,include_all
      @attributes||=Hash.new
      key=symbol.id2name.chomp('?').chomp('=').sub(/^has_/,"")
      if @attributes.has_key?(:"#{key}")
          return true
      else
        super(symbol,include_all)
      end
    end
  end

  ##
  # A Rutema::Specification encompasses all elements required to run a test, the builds used, the scenario to run,
  # together with a textual description and information that aids in tracing the test back to the requirements.
  class Specification
    include SpecificationElement

    attr_accessor :scenario
    ##
    # Expects a Hash of parameters
    #
    # Following keys have meaning in initialization:
    #
    # :name - the name of the testcase. Should uniquely identify the testcase
    #
    # :title - a one liner describing what the testcase does
    #
    # :filename - the filename describing the testcase
    #
    # :description - a full textual description for the testcase. To be used in reports and documents
    #
    # :scenario - An instance of Rutema::Scenario
    #
    # :version - The version of this specification
    #
    # Default values are empty strings and arrays. (scenario is nil)
    def initialize params
      begin
        @attributes=params
      end if params
      @attributes||=Hash.new
      @attributes[:name]||=""
      @attributes[:title]||=""
      @attributes[:filename]||=""
      @attributes[:description]||=""
      @scenario=@attributes[:scenario]
    end

    ##
    # Create a concise string representation consisting of +name+ and +title+
    def to_s
      return "#{@attributes[:name]} - #{@attributes[:title]}"
    end
  end

  #A Rutema::Scenario is a sequence of Rutema::Step instances.
  #
  #Rutema::Step instances are run in the definition sequence and the scenario
  #is succesfull when all steps are succesfull. 
  #
  #From the execution point of view each step is either succesfull or failed and it depends on 
  #the exit code of the step's command. 
  #
  #Failure in a step results in the interruption of execution and the report of the errors.
  class Scenario
    include SpecificationElement

    attr_reader :steps
    
    def initialize steps
      @attributes=Hash.new
      @steps=steps
      @steps||=Array.new
    end

    #Adds a step at the end of the step sequence
    def add_step step
      @steps<<step
    end

    #Overwrites the step sequence
    def steps= array_of_steps
      @steps=array_of_steps
    end
  end

  #Represents a step in a Scenario.
  #
  #Each Rutema::Step can have text and a command associated with it. 
  #
  #Step standard attributes are.
  #
  #attended - the step can only run in attended mode, it requires user input.
  #
  #step_type - a string identifying the type of the step. It is "step" by default.
  #
  #ignore - set to true if the step's success or failure is to be ignored. It essentially means that the step is always considered succesfull
  #
  #continue - set to true if the step's success or failure is to be recognized, but following steps in the same scenario are to be carried out regardless
  #  of if indicates test failure, but ensures any further state is carried out as needed
  #
  # skip_on_error - if the test case has been marked a failure, skip steps marked with this attribute
  #
  #number - this is set when the step is assigned to a Scenario and is the sequence number
  #
  #cmd - the command associated with this step. This should quack like Patir::Command.
  #
  #status - one of :not_executed, :success, :warning, :error. Encapsulates the underlying command's status
  #
  #==Dynamic behaviour
  #
  #A Rutema::Step can be queried dynamicaly about the attributes it posesses:
  # step.has_script? - will return true if script is step's attribute.
  #Attribute's are mostly assigned by the parser, i.e. the Rutema::BaseXMLParser from the XML element
  # <test script="some_script"/>
  #will create a Step instance with step_type=="test" and script="some_script". In this case
  #
  # step.has_script? returns true
  # step.script returns "some_script"
  #
  #Just like an OpenStruct, Step attributes will be created by direct assignment:
  # step.script="some_script" creates the script attribute if it does not exist.
  #
  #See Rutema::SpecificationElement for the implementation details. 
  class Step
    include SpecificationElement
    include Patir::Command
    
    #_txt_ describes the step, _cmd_ is the command to run
    def initialize txt="",cmd=nil
      @attributes=Hash.new
      #ignore is off by default
      @attributes[:ignore]=false
      # continue is off by default
      @attributes[:continue] = false
      # skip_on_error is off by default
      @attributes[:skip_on_error]=false
      #assign
      @attributes[:cmd]=cmd if cmd
      @attributes[:text]=txt
      @number=0
      @attributes[:step_type]="step"
    end

    def name
      return name_with_parameters
    end

    def output
      return "" unless @attributes[:cmd]
      return @attributes[:cmd].output
    end

    def error
      return "no command associated" unless @attributes[:cmd]
      return @attributes[:cmd].error
    end

    def backtrace
      return "no backtrace associated" unless @attributes[:cmd]
      return @attributes[:cmd].backtrace if @attributes[:cmd].respond_to?(:backtrace)
      return ""
    end

    def skip_on_error?
      return false unless @attributes[:skip_on_error]
      return @attributes[:skip_on_error]
    end

    def ignore?
      return false unless @attributes[:ignore]
      return @attributes[:ignore]
    end

    def continue?
      return false unless @attributes[:continue]
      return @attributes[:continue]
    end

    def exec_time
      return 0 unless @attributes[:cmd]
      return @attributes[:cmd].exec_time
    end

    def status
      return :warning unless @attributes[:cmd]
      return @attributes[:cmd].status
    end

    def status= st
      @attributes[:cmd].status=st if @attributes[:cmd]
    end

    def run context=nil
      return not_executed unless @attributes[:cmd]
      return @attributes[:cmd].run(context)
    end

    def reset
      @attributes[:cmd].reset if @attributes[:cmd]
    end

    def name_with_parameters
      param=" - #{self.cmd.to_s}" if self.has_cmd?
      return "#{@attributes[:step_type]}#{param}"
    end

    def to_s#:nodoc:
      if self.has_cmd?
        msg="#{self.number} - #{self.cmd.to_s}"
      else
        msg="#{self.number} - #{self.name}"
      end
        msg<<" in #{self.included_in}" if self.has_included_in?
      return msg
    end
  end
end

class Patir::ShellCommand
  def to_s#:nodoc:
    return @command
  end
end

class Patir::RubyCommand
  def to_s#:nodoc:
    return @name
  end
end
