#  Copyright (c) 2007 Vassilis Rizopoulos. All rights reserved.

require 'patir/base'
module Patir
  #This exception is thrown when encountering a configuration error
  class ConfigurationException<RuntimeError
  end
  
  #Configurator is the base class for all the Patir configuration classes.
  # 
  #The idea behind the configurator is that the developer creates a module that contains as methods
  #all the configuration directives.
  #He then derives a class from Configurator and includes the directives module. 
  #The Configurator loads the configuration file and evals it with itself as context (variable configuration), so the directives become methods in the configuration file:
  # configuration.directive="some value"
  # configuration.other_directive={:key=>"way to group values together",:other_key=>"omg"}
  #
  #The Configurator instance contains all the configuration data.
  #Configurator#configuration method is provided as a post-processing step. It should be overriden to return the configuration data in the desired format and perform any overall validation steps (single element validation steps should be done in the directives module).
  #==Example
  # module SimpleConfiguration
  #   def name= tool_name
  #     raise Patir::ConfigurationException,"Inappropriate language not allowed" if tool_name=="@#!&@&$}"
  #     @name=tool_name
  #   end
  # end
  #   
  # class SimpleConfigurator
  #   include SimpleConfiguration
  #     
  #   def configuration
  #     return @name
  #   end
  # end
  #The configuration file would then be 
  # configuration.name="really polite name"
  #To use it you would do
  # cfg=SimpleConfigurator.new("config.cfg").configuration
  class Configurator
    attr_reader :logger,:config_file
    def initialize config_file,logger=nil
      @logger=logger
      @logger||=Patir.setup_logger
      @config_file=config_file
      load_configuration(@config_file)
    end
    
    #Returns self. This should be overriden in the actual implementations
    def configuration
      return self
    end
    
    #Loads the configuration from a file
    #
    #Use this to chain configuration files together
    #==Example
    #Say you have on configuration file "first.cfg" that contains all the generic directives and several others that change only one or two things. 
    #
    #You can 'include' the first.cfg file in the other configurations with
    # configuration.load_from_file("first.cfg")
    def load_from_file filename
      load_configuration(filename)
    end
    private
    def load_configuration filename
      begin 
        #change into the directory of the configuration file to make requiring easy
        prev_dir=Dir.pwd
        Dir.chdir(File.dirname(filename))
        cfg_txt=File.readlines(File.basename(filename))
        configuration=self
        eval(cfg_txt.join(),binding())
        @logger.info("Configuration loaded from #{filename}") if @logger
      rescue ConfigurationException
        #pass it on, do not wrap again
        raise
      rescue SyntaxError
        #Just wrap the exception so we can differentiate
        @logger.debug($!)
        raise ConfigurationException.new,"Syntax error in the configuration file '#{filename}':\n#{$!.message}"
      rescue NoMethodError
        @logger.debug($!)
        raise ConfigurationException.new,"Encountered an unknown directive in configuration file '#{filename}':\n#{$!.message}"
      rescue 
        @logger.debug($!)
        #Just wrap the exception so we can differentiate
        raise ConfigurationException.new,"#{$!.message}"
      ensure
        #ensure we go back to our previous dir
        Dir.chdir(prev_dir)
      end
    end
  end
end