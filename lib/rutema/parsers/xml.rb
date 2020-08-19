# Copyright (c) 2007-2020 Vassilis Rizopoulos. All rights reserved.
require 'English'
require 'patir/command'
require 'rexml/document'
require_relative '../core/parser'
require_relative '../core/objectmodel'
require_relative '../elements/minimal'

module Rutema
  module Parsers
    ##
    # Rutema::Parsers::XML is a basic XML parser that can easily be extended
    #
    # Parsers derived from this class should define for each element +foo+ that
    # shall be parsed a method element_foo(step). This method receives a
    # Rutema::Step instance, configures it accordingly to the parsed XML and
    # returns it afterwards.
    #
    # The Rutema::Elements::Minimal module can be taken as an example of a mixin
    # for the accumulation of +element_+ methods.
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
      # Parse +param+ and return a respective Rutema::Specification instance
      #
      # +param+ can be the filename of a specification or text of a specification
      #
      # Rutema::ParserError will be thrown if an error occurrs.
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
          @parsed << spec.name
          extension_handling(spec)
        rescue REXML::ParseException
          raise Rutema::ParserError,$!.message
        end
      end

      private

      #Parses the XML specification of a testcase and creates the corresponding Rutema::Specification instance
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

      #Validates the XML file from our point of view.
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
        step.continue = false
        step.ignore=false
        step.continue=false
        xmldoc.root.attributes.each do |attr,value|
         add_attribute(step,attr,value)
        end
        step.text=xmldoc.root.text.strip if xmldoc.root.text
        step.step_type=xmldoc.root.name
        return step
      end

      def add_attribute element,attr,value
        if boolean?(value)
         element.attribute(attr,eval(value))
        else
          element.attribute(attr,value)
        end
      end

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

      def extension_handling spec
        #change into the directory the spec is in to handle relative paths correctly
        Dir.chdir(File.dirname(File.expand_path(spec.filename))) do |path|
          spec.scenario.steps.each do |step|
            #do we have a method to handle the element?
            if respond_to?(:"element_#{step.step_type}")
              begin
                self.send(:"element_#{step.step_type}",step)
              rescue
                raise ParserError, ($ERROR_INFO.message + "\n" + $ERROR_POSITION.join("\n"))
              end #begin
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
