#  Copyright (c) 2007-2011 Vassilis Rizopoulos. All rights reserved.
$:.unshift File.join(File.dirname(__FILE__),'..','..')
require 'rexml/document'
require 'patir/command'
require 'rutema/objectmodel'
require 'rutema/parsers/base'
require 'rutema/elements/minimal'

module Rutema
  #BaseXMLParser encapsulates all the XML parsing code
  class BaseXMLParser<SpecificationParser
    ELEM_SPEC="specification"
    ELEM_DESC="specification/description"
    ELEM_TITLE="specification/title"
    ELEM_SCENARIO="specification/scenario"
    ELEM_REQ="requirement"
    #Parses __param__ and returns the Rutema::TestSpecification instance
    #
    #param can be the filename of the specification or the contents of that file.
    #
    #Will throw ParserError if something goes wrong
    def parse_specification param
      @logger.debug("Loading #{param}")
      begin
        if File.exists?(param)
          #read the file
          txt=File.read(param)
          filename=File.expand_path(param)
        else
          filename=Dir.pwd
          #try to parse the parameter
          txt=param
        end
        spec=parse_case(txt,filename)
        raise "Missing required attribute 'name' in specification element" unless spec.has_name? && !spec.name.empty?
        return spec
      rescue
        @logger.debug($!)
        raise ParserError,"Error loading #{param}: #{$!.message}"
      end
    end
    
    private
    #Parses the XML specification of a testcase and creates the corresponding TestSpecification instance
    def parse_case xmltxt,filename
      #the testspec to return
      spec=TestSpecification.new
      #read the test spec
      xmldoc=REXML::Document.new( xmltxt )
      #validate it
      validate_case(xmldoc)
      #parse it
      el=xmldoc.elements[ELEM_SPEC]
      xmldoc.root.attributes.each do |attr,value|
        add_attribute(spec,attr,value)
      end
      #get the title
      spec.title=xmldoc.elements[ELEM_TITLE].text
      spec.title||=""
      spec.title.strip!
      #get the description
      #strip line feeds, cariage returns and remove all tabs
      spec.description=xmldoc.elements[ELEM_DESC].text
      spec.description||=""
      begin
        spec.description.strip!
        spec.description.gsub!(/\t/,'')  
      end unless spec.description.empty?
      #get the requirements
      reqs=el.elements.select{|e| e.name==ELEM_REQ}
      reqs.collect!{|r| r.attributes["name"]}
      spec.requirements=reqs
      #Get the scenario
      Dir.chdir(File.dirname(filename)) do
        spec.scenario=parse_scenario(xmldoc.elements[ELEM_SCENARIO].to_s) if xmldoc.elements[ELEM_SCENARIO]
      end
      spec.filename=filename
      return spec
    end
    #Validates the XML file from our point of view.
    #
    #Checks for the existence of ELEM_SPEC, ELEM_DESC and ELEM_TITLE and raises ParserError if they're missing.
    def validate_case xmldoc
      raise ParserError,"missing #{ELEM_SPEC} element" unless xmldoc.elements[ELEM_SPEC]
      raise ParserError,"missing #{ELEM_DESC} element" unless xmldoc.elements[ELEM_DESC]
      raise ParserError,"missing #{ELEM_TITLE} element" unless xmldoc.elements[ELEM_TITLE]
    end
    
    #Parses the scenario XML element and returns the Rutema::TestScenario instance
    def parse_scenario xmltxt
      @logger.debug("Parsing scenario from #{xmltxt}")
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
            @logger.debug("Adding included step #{st}")
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
      @logger.debug("Including file from #{step}")
      raise ParserError,"missing required attribute file in #{step}" unless step.has_file?
      raise ParserError,"Cannot find #{File.expand_path(step.file)}" unless File.exists?(File.expand_path(step.file))
      #Load the scenario
      step.file=File.expand_path(step.file)
      include_content=File.read(step.file)
      @logger.debug(include_content)
      return parse_scenario(include_content)
    end
  end
  #The ExtensibleXMLParser allows you to easily add methods to handle specification elements.
  #
  #A method element_foo(step) allows you to add behaviour for foo scenario elements.
  #
  #The method will receive a Rutema::TestStep instance. 
  class ExtensibleXMLParser<BaseXMLParser
    def parse_specification param
      spec = super(param)
      #change into the directory the spec is in to handle relative paths correctly
      Dir.chdir(File.dirname(File.expand_path(spec.filename))) do |path|
        #iterate through the steps
        spec.scenario.steps.each do |step|
          #do we have a method to handle the element?
          if respond_to?(:"element_#{step.step_type}")
            begin
              self.send(:"element_#{step.step_type}",step)
            rescue
              raise ParserError, $!.message
            end
          end
        end
      end
      return spec
    end
  end
  #MinimalXMLParser offers three runnable steps in the scenarios as defined in Rutema::Elements::Minimal
  class MinimalXMLParser<ExtensibleXMLParser
    include Rutema::Elements::Minimal
  end
end