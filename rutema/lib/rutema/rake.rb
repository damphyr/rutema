require 'rutema/system'
require 'optparse'

module Rutema
  #Integrates rutema with rake
  class RakeTask
    attr_accessor :config_file, :log_file, :name
    #Params is a parameter hash.
    #
    #Valid parameters are:
    #
    #:config_file => path to the configuration file
    #
    #:log_file => path to the file where the log is saved. If missing then the logger prints in stdout
    #
    #:name => the name for the rutema task. If missing then the task is named rutema, otherwise it will be rutema:name
    def initialize params=nil
      params||={}
      @config_file=params[:config]
      @log_file=params[:log]
      @name=params[:name]
      yield self if block_given?
      
      raise "No rutema configuration given" unless @config_file
      args=['-c',@config_file]
      args+=['-l',@log_file] if @log_file
      args<<"all"
      OptionParser::Arguable.extend_object(args)
      if @name
        desc "Executes the tests in #{File.basename(@config_file)}" 
        task :"rutema:#{@name}" do
          Rutema::RutemaX.new(args)
        end
      else
        desc "Executes the tests in #{File.basename(@config_file)}" 
        task :rutema do
          Rutema::RutemaX.new(args)
        end
      end
    end
  end
end