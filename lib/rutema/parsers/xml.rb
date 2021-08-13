#  Copyright (c) 2007-2021 Vassilis Rizopoulos. All rights reserved.

require 'rexml/document'
require 'patir/command'
require_relative '../core/parser'
require_relative '../core/objectmodel'
require_relative '../elements/minimal'

module Rutema
  module Parsers
    ##
    # Basic and easily extendable parser for test specifications in XML format
    #
    # Actual XML specification parsers should be derived from this class and
    # define for each specification element +foo+ to be parsed a method
    # +element_foo+.
    #
    # The method will receive a Rutema::Step instance as a parameter which it should return
    class XML<SpecificationParser
      include Rutema::Elements::Minimal

      #:nodoc:
      ELEM_SPEC="specification"
      #:nodoc:
      ELEM_DESC="specification/description"
      #:nodoc:
      ELEM_TITLE="specification/title"
      #:nodoc:
      ELEM_SCENARIO="specification/scenario"

      ##
      # Pass the given test specification and return a corresponding
      # Specification instance
      #
      # The passed argument can either be the path to a test specification file
      # or the test specification itself.
      #
      # This will raise ParserError if an error occurs during parsing.
      def parse_specification param
        @parsed||=[]
        begin
          if File.exist?(param)
            txt=File.read(param)
            filename=File.expand_path(param)
          else
            txt=param
            filename=Dir.pwd
          end
          spec=parse_case(txt,filename)
          raise Rutema::ParserError,"Missing required attribute 'name' in specification element" unless spec.has_name? && !spec.name.empty?
          raise Rutema::ParserError,"Duplicate test name '#{spec.name}' in #{filename}" if @parsed.include?(spec.name)
          @parsed<<spec.name
          extension_handling(spec)
        rescue REXML::ParseException
          raise Rutema::ParserError,$!.message
        end
      end

      private

      ##
      # Parse the XML specification of a testcase and create a corresponding
      # Rutema::Specification instance
      #
      # * +xmltext+ - the actual test specification text which must be an XML
      #   document
      # * +filename+ - the filename of the test specification file or the
      #   current working directory of the test execution (this 
      def parse_case xmltxt,filename
        spec=Rutema::Specification.new({})
        xmldoc=REXML::Document.new( xmltxt )
        validate_case(xmldoc)
        xmldoc.root.attributes.each do |attr,value|
          add_attribute(spec,attr,value)
        end
        spec.title=xmldoc.elements[ELEM_TITLE].text
        spec.title||=""
        spec.title.strip!
        spec.description=xmldoc.elements[ELEM_DESC].text
        spec.description||=""
        unless spec.description.empty?
          spec.description.strip!
          spec.description.gsub!(/\t/,'')  
        end 
        Dir.chdir(File.dirname(filename)) do
          spec.scenario=parse_scenario(xmldoc.elements[ELEM_SCENARIO].to_s) if xmldoc.elements[ELEM_SCENARIO]
        end
        spec.filename=filename
        return spec
      end

      ##
      # Conduct a simple validation of the XML document by checking if it
      # contains all necessary elements
      #
      # ParserError is being raised if any of the necessary elements is missing.
      #
      # * +xmldoc+ - the text of the XML document to be checked for the
      # necessary elements
      def validate_case xmldoc
        raise Rutema::ParserError,"missing #{ELEM_SPEC} element in #{xmldoc}" unless xmldoc.elements[ELEM_SPEC]
        raise Rutema::ParserError,"missing #{ELEM_DESC} element in #{xmldoc}" unless xmldoc.elements[ELEM_DESC]
        raise Rutema::ParserError,"missing #{ELEM_TITLE} element in #{xmldoc}" unless xmldoc.elements[ELEM_TITLE]
      end

      #Parses the 'scenario' XML element and returns the Rutema::Scenario instance
      def parse_scenario xmltxt
        scenario=Rutema::Scenario.new([])
        xmldoc=REXML::Document.new( xmltxt )
        xmldoc.root.attributes.each do |attr,value|
          add_attribute(scenario,attr,value)
        end
        number=0
        xmldoc.root.elements.each do |el| 
          step=parse_step(el.to_s)
          if step.step_type=="include_scenario"
            included_scenario=include_scenario(step)
            included_scenario.steps.each do |st|
              number+=1
              st.number=number
              st.included_in=step.file
              scenario.add_step(st)
            end
          else
            number+=1
            step.number=number
            scenario.add_step(step)
          end
        end
        return scenario
      end

      #Parses xml and returns the Rutema::Step instance
      def parse_step xmltxt
        xmldoc=REXML::Document.new( xmltxt )
        #any step element
        step=Rutema::Step.new()
        step.ignore=false
        step.continue=false
        xmldoc.root.attributes.each do |attr,value|
         add_attribute(step,attr,value)
        end
        step.text=xmldoc.root.text.strip if xmldoc.root.text
        step.step_type=xmldoc.root.name
        return step
      end

      ##
      # Add an attribute of a given name with the given value to a specification
      # element
      #
      # * +element+ - the specification element the attribute shall be added to
      # * +attr+ - the name of the attribute which shall either be created or
      #   whose current value will be overridden
      # * +value+ - the value which shall be set for the attribute
      def add_attribute element,attr,value
        # If the string is a textual representation of a boolean value ...
        if boolean?(value)
          # ... convert it to a boolean value
         element.attribute(attr,eval(value))
        else
          element.attribute(attr,value)
        end
      end

      ##
      # Check if attribute_value is a string representing a boolean value
      #
      # This returns +true+ if the string is "true" or "false" or +false+
      # otherwise.
      #
      # * +attribute_value+ - the entity which shall be checked if it's a string
      # representing a boolean value
      def boolean? attribute_value
        return true if attribute_value=="true" || attribute_value=="false"
        return false
      end

      #handles <include_scenario> elements, adding the steps to the current scenario
      def include_scenario step
        raise Rutema::ParserError,"missing required attribute file in #{step}" unless step.has_file?
        raise Rutema::ParserError,"Cannot find #{File.expand_path(step.file)}" unless File.exist?(File.expand_path(step.file))
        step.file=File.expand_path(step.file)
        include_content=File.read(step.file)
        return parse_scenario(include_content)
      end

      ##
      # 
      def extension_handling spec
        #change into the directory the spec is in to handle relative paths correctly
        Dir.chdir(File.dirname(File.expand_path(spec.filename))) do |path|
          spec.scenario.steps.each do |step|
            #do we have a method to handle the element?
            if respond_to?(:"element_#{step.step_type}")
              begin
                self.send(:"element_#{step.step_type}",step)
              rescue
                raise ParserError, ($!.message + "\n" + $@.join("\n"))
              end#begin
            elsif @configuration.parser["strict_mode"]
              raise ParserError,"No command element associated with #{step.step_type}. Missing element_#{step.step_type}"
            end
          end#each
        end#chdir
        return spec
      end
    end
  end
end
