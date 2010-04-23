$:.unshift File.join(File.dirname(__FILE__),"..")
require 'rutema_web/sinatra'
require 'optparse'
require 'rutema/reporters/activerecord'
#This is the web frontend for Rutema databases.
module RutemaWeb
  extend Rutema::ActiveRecordConnections
  #This module defines the version numbers for the library
  module Version
    MAJOR=1
    MINOR=0
    TINY=4
    STRING=[ MAJOR, MINOR, TINY ].join( "." )
  end
  #Starts App
  def self.start
    logger=Patir.setup_logger
    cfg_file=parse_command_line(ARGV)
    cfg_file=File.expand_path(cfg_file)
    configuration=YAML.load_file(cfg_file)
    if (configuration[:db])
      self.connect_to_active_record(configuration[:db],logger)
      RutemaWeb::UI::SinatraApp.define_settings(configuration[:settings])
      RutemaWeb::UI::SinatraApp.run!
    else
      logger.fatal("No database configuration information found in #{cfg_file}")
    end
  end
  #Parses the command line arguments
  def self.parse_command_line args
    args.options do |opt|
      opt.on("Usage:")  
      opt.on("rutema_web [options] config_file")
      opt.on("Options:")
      opt.on("--debug", "-d","Turns on debug messages") { $DEBUG=true }
      opt.on("-v", "--version","Displays the version") { $stdout.puts("v#{Version::STRING}");exit 0 }
      opt.on("--help", "-h", "-?", "This text") { $stdout.puts opt; exit 0 }
      opt.parse!
      #and now the rest
      if args.empty?
        $stdout.puts opt 
        exit 0
      else
        return args.shift
      end
    end
  end

end



