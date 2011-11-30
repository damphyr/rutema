$:.unshift File.join(File.dirname(__FILE__),"..")
require 'optparse'
require 'patir/base'
require 'rutema_web/activerecord/model'
require 'rutema_web/sinatra'
#This is the web frontend for Rutema databases.
module RutemaWeb
  #This module defines the version numbers for the library
  module Version
    MAJOR=1
    MINOR=0
    TINY=6
    STRING=[ MAJOR, MINOR, TINY ].join( "." )
  end
  #Starts App
  def self.start(cfg_file)
    logger=Patir.setup_logger
    if File.exists?(cfg_file)
      Dir.chdir(File.dirname(cfg_file)) do
        configuration=YAML.load_file(cfg_file)
        if (configuration[:db])
          Rutema::ActiveRecord.connect(configuration[:db],logger)
          RutemaWeb::UI::SinatraApp.define_settings(configuration[:settings])
          RutemaWeb::UI::SinatraApp.run!
        else
          logger.fatal("No database configuration information found in #{cfg_file}")
        end
      end
    else
      logger.fatal("Could not find rutema_web.yaml")
    end
  end
  
  #Creates the scaffolding for a new rutema_web instance
  def self.scaffolding target_dir
    if File.exists?(target_dir)
      unless File.directory?(target_dir)
       puts "FATAL: '#{target_dir}' exists but is not a directory"
      exit 1
      end
    else
      FileUtils.mkdir_p(target_dir)
    end
    gemfile=File.join(File.dirname(__FILE__),'../../Gemfile')
    config=File.join(File.dirname(__FILE__),'../../examples/rutema_web.yaml')
    FileUtils.cp(config,target_dir,:verbose=>false)
    FileUtils.cp(gemfile,target_dir,:verbose=>false)
    puts "Done!"
    puts "You should now do\n\tbundle install\n\trutema_web\nto start "
  end
end

