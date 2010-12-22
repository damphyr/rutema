require 'rutema/system'
require 'optparse'
require 'rake'

module Rutema
  #Integrates rutema with rake.
  #
  #You can pass a hash with the parameters or use the block syntax:
  # RakeTask.new do |rt|
  #   rt.config_file="config.rutema"
  #   rt.dependencies=[]
  #   rt.add_dependency("some_other_task")
  #   rt.name="name"
  #   rt.log_file="."
  # end
  class RakeTask
    attr_accessor :config_file, :log_file, :name
    attr_reader :rake_task
    #Params is a parameter hash.
    #
    #Valid parameters are:
    #
    #:config_file => path to the configuration file
    #
    #:log_file => path to the file where the log is saved. If missing then the logger prints in stdout
    #
    #:name => the name for the rutema task. If missing then the task is named rutema, otherwise it will be rutema:name
    #
    #:dependencies => an array of dependencies for the task
    def initialize params=nil
      params||={}
      @config_file=params[:config_file]
      @log_file=params[:log]
      @name=params[:name]
      @dependencies=params[:dependencies]
      yield self if block_given?
      @dependencies||=[]
      raise "No rutema configuration given, :config_file is nil" unless @config_file
      args=['-c',@config_file]
      args+=['-l',@log_file] if @log_file
      args<<"all"
      OptionParser::Arguable.extend_object(args)
      if @name
        desc "Executes the tests in #{File.basename(@config_file)}" 
        @rake_task=task :"rutema:#{@name}" do
          Rutema::RutemaX.new(args)
        end
      else
        desc "Executes the tests in #{File.basename(@config_file)}" 
        @rake_task=task :rutema do
          Rutema::RutemaX.new(args)
        end
      end
    end
    #Adds a dependency to the rutema task created
    def add_dependency dependency
      task @rake_task => [dependency]
    end
  end
end