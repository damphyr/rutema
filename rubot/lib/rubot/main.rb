#  Copyright (c) 2008 Vassilis Rizopoulos. All rights reserved.
$:.unshift File.join(File.dirname(__FILE__),"..")
require	'optparse'
require 'fileutils'
require 'rubygems'
require 'patir/base'
module Rubot
  #Check the command line parameters
  def parse_command_line
    @log_to_file=true
    ARGV.options { |opt|
      opt.on("Options:")
      opt.on("--basedir PATH", "-b",String,"Use PATH as working directory"){|@base_dir|}
      opt.on("--debug", "-d","Debugging mode"){$DEBUG=true}
      opt.on("--no-log", "Log to STDOUT"){@log_to_file=false}
      opt.parse!
    }
  end
  #Starts a rubot worker
  def self.start_worker base,log_to_file=true,cfgfile=nil,logfile=nil
    require 'rubot/worker/ramaze_controller'
    cfgfile||=Rubot::Worker::CFG
    logfile||=Rubot::Worker::LOG
    #setup a logger
    logger=log_to_file ? Patir.setup_logger(logfile) : Patir.setup_logger
    unless File.exists?(cfgfile)
      cfgfile=File.join(base,cfgfile) 
    else
      logger.warn("Could not find configuration file '#{cfgfile}'")
    end
    if File.exists?(cfgfile)
      logger.info("Reading '#{cfgfile}'")
      cfg=Rubot::Worker::Configurator.new(cfgfile,logger).configuration
      cfg.base = File.expand_path(base)
      cfg.logging_to_file = log_to_file
      #We need the worker
      logger.info("Starting Rubot Worker")
      @@coordinator=Worker::Coordinator.new(cfg)
      logger.info("Starting Ramaze")
      Dir.chdir(File.join(File.dirname(__FILE__),"worker"))
      Ramaze.start :force=>true,:host=>cfg.endpoint[:ip],:port=>cfg.endpoint[:port]#,:adapter=>:thin
    else
      logger.fatal("Could not find configuration file '#{cfgfile}'")
      exit 1
    end
  end
  #Starts a rubot overseer
  def self.start_overseer base,log_to_file=true,cfgfile=nil,logfile=nil
    require 'rubot/overseer/main'
    cfgfile||=Rubot::Overseer::CFG
    logfile||=Rubot::Overseer::LOG
    unless base
      $stderr.puts("No base directory defined")
      exit 1
    end
    base=File.expand_path(base)
    logfile=File.join(base,logfile)
    unless File.exists?(cfgfile)
      cfgfile=File.join(base,cfgfile) 
    else
      logger.warn("Could not find configuration file '#{cfgfile}'")
    end
    #setup a logger
    logger=log_to_file ? Patir.setup_logger(logfile) : Patir.setup_logger
    if File.exists?(cfgfile)
      logger.info("Reading '#{cfgfile}'")
      cfg=Rubot::Overseer::Configurator.new(cfgfile,logger).configuration
      cfg.base = base
      cfg.logging_to_file = log_to_file
      #We need the Overseer
      logger.info("Starting Rubot Overseer")
      @@coordinator=Overseer::Coordinator.new(cfg)
      logger.info("Starting Ramaze")
      require 'rubot/overseer/ramaze_controller'
      Rubot::Overseer.ramaze_settings      
      Ramaze.start :force=>true,:host=>cfg.interface[:ip],:port=>cfg.interface[:port]#,:adapter=>:thin
    else
      logger.fatal("Could not find configuration file '#{cfgfile}'")
      exit 1
    end
  end
  #Sets up a rubot overseer base directory with sample configuration, sequence, worker and rules files
  def setup_overseer base
    logger=Patir.setup_logger
    unless base
     logger.fatal("No base directory defined")
      exit 1
    end
    base=File.expand_path(base)
    if File.exists?(base)
      logger.fatal("#{base} already exists.")
      exit 1
    end
    FileUtils.mkdir_p(File.join(base,"sequences"),:verbose=>false)
    FileUtils.mkdir_p(File.join(base,"rules"),:verbose=>false)
    FileUtils.mkdir_p(File.join(base,"workers"),:verbose=>false)
    logger.info("Ready!")
  end
  #Tells you how to use help
  def self.offer_help
    puts "Use 'rubot help' to see a list of commands or 'rubot help [command]' to get more info on a command"
  end
  def self.help
    puts"Available commands:"
    puts "overseer : starts the rubot overseer server with the given base directory (defined with -b)"
    puts "worker : starts a rubot worker with the given base directory (defined with -b)"
    puts "setup_overseer: sets up the basic structure of an overseer installation in the given base directory"
  end 
end