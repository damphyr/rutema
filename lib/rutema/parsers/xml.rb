#  Copyright (c) 2007-2013 Vassilis Rizopoulos. All rights reserved.
require 'rexml/document'
require 'patir/command'
require_relative '../core/objectmodel'
require_relative 'base'
require_relative '../elements/minimal'

module Rutema
  module Parsers
    #ExensibleXMLParser is a basic XML parser that is easily extended
    #
    #Derive your parser from this class and define for each element 'foo' that you want to parse 
    #a method element_foo(step)
    #
    #The method will receive a Rutema::TestStep instance as a parameter which it should return
    class ExtensibleXMLParser<SpecificationParser
      #:nodoc:
      ELEM_SPEC="specification"
      #:nodoc:
      ELEM_DESC="specification/description"
      #:nodoc:
      ELEM_TITLE="specification/title"
      #:nodoc:
      ELEM_SCENARIO="specification/scenario"
      #Parses __param__ and returns the Rutema::TestSpecification instance
      #
      #param can be the filename of the specification or the contents of that file.
      #
      #Will throw Rutema::ParserError if something goes wrong
      def parse_specification param
        begin
          if File.exists?(param)
            txt=File.read(param)
            filename=File.expand_path(param)
          else
            txt=param
            filename=Dir.pwd
          end
          spec=parse_case(txt,filename)
          raise Rutema::ParserError,"Missing required attribute 'name' in specification element" unless spec.has_name? && !spec.name.empty?
          extension_handling(spec)
        rescue
          raise Rutema::ParserError,"Error loading #{param}: #{$!.message}"
        end
      end
      private
      #Parses the XML specification of a testcase and creates the corresponding TestSpecification instance
      def parse_case xmltxt,filename
        spec=TestSpecification.new
        xmldoc=REXML::Document.new( xmltxt )
        validate_case(xmldoc)
        el=xmldoc.elements[ELEM_SPEC]
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
        raise Rutema::ParserError,"missing #{ELEM_SPEC} element" unless xmldoc.elements[ELEM_SPEC]
        raise Rutema::ParserError,"missing #{ELEM_DESC} element" unless xmldoc.elements[ELEM_DESC]
        raise Rutema::ParserError,"missing #{ELEM_TITLE} element" unless xmldoc.elements[ELEM_TITLE]
      end
      #Parses the 'scenario' XML element and returns the Rutema::TestScenario instance
      def parse_scenario xmltxt
        scenario=Rutema::TestScenario.new
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
      #Parses xml and returns the Rutema::TestStep instance
      def parse_step xmltxt
        xmldoc=REXML::Document.new( xmltxt )
        #any step element
        step=Rutema::TestStep.new()
        step.ignore=false
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
        raise Rutema::ParserError,"Cannot find #{File.expand_path(step.file)}" unless File.exists?(File.expand_path(step.file))
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
                raise ParserError, $!.message
              end
            end#begin
          end#each
        end#chdir
        return spec
      end
    end
  end
end
