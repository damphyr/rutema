$:.unshift File.join(File.dirname(__FILE__),"..")
require 'rutema_web/gems'
require 'rutema_web/ramaze_controller'

#This is the web frontend for Rutema databases.
#
module RutemaWeb
  #This module defines the version numbers for the library
  module Version
    MAJOR=0
    MINOR=9
    TINY=5
    STRING=[ MAJOR, MINOR, TINY ].join( "." )
  end
  #Starts Ramaze
  def self.start_ramaze
    logger=Patir.setup_logger
    db_file=parse_command_line(ARGV)
    db_file=File.expand_path(db_file)
    Rutema.connect_to_ar(db_file,logger)  
    Rutema::UI.ramaze_settings
    Ramaze.start :force=>true
  end
  #Parses the command line arguments
  def self.parse_command_line args
    args.options do |opt|
      opt.on("Usage:")
      opt.on("rutemaweb [options] database_file")
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



