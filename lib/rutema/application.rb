# Copyright (c) 2007-2020 Vassilis Rizopoulos. All rights reserved.

require 'optparse'

require_relative 'core/configuration'
require_relative 'core/engine'

##
# Rutema is the base module of all modules in the _rutema_ library.
module Rutema
  ##
  # This class is the entry point to the execution of _rutema_
  #
  # Upon initialization it parses the commandline, sets up its execution
  # Rutema::Configuration according to the passed configuration file and
  # launches Rutema::Engine
  class App
    ##
    # Parse commandline arguments, read the given configuration file and start
    # the application flow
    def initialize(command_line_args)
      parse_command_line(command_line_args)

      @configuration = Rutema::Configuration.new(@config_file)
      @configuration.context ||= {}
      @configuration.context[:config_file] = File.expand_path(@config_file)
      @configuration.context[:config_name] = File.basename(@config_file)
      @configuration.context[:start_time] = Time.now
      @configuration.reporters ||= {}
      @configuration.reporters[Rutema::Reporters::Console] \
        ||= { class: Rutema::Reporters::Console, 'silent' => @silent } unless @bare
      @configuration.reporters[Rutema::Reporters::Summary] \
        ||= { class: Rutema::Reporters::Summary, 'silent' => (@silent || @bare) }
      @engine = Rutema::Engine.new(@configuration)

      application_flow
    end

    private

    ##
    # Parse the commandline
    #
    # The only mandatory option is the configuration file.
    def parse_command_line(args)
      args.options do |opt|
        opt.on("rutema v#{Version::STRING}")
        opt.on('Options:')
        opt.on('--config FILE', '-c FILE', String, 'Loads the configuration from FILE') \
          { |config_file| @config_file = config_file }
        opt.on('--check', 'Runs just the suite setup test') { @check = true }
        # opt.on('--step', 'Runs test cases step by step') { @step = true }
        opt.on('--silent', 'Suppresses console output (only for the default reporters)') { @silent = true }
        opt.on('--bare', 'No default reporters whatsoever') { @bare = true }
        # opt.on('--color','Adds color to the Console reporter') { @color = true }
        opt.on('-v', '--version', 'Displays the version') do
          $stdout.puts("rutema v#{Version::STRING}")
          exit 0
        end
        opt.on('--help', '-h', '-?', 'This text') do
          $stdout.puts opt
          exit 0
        end
        opt.on('--debug', '-d', 'Turn on debug messages') { $DEBUG = true }
        opt.on('You can provide a specification filename in order to run a single test')
        opt.parse!
        # and now the rest
        unless @config_file
          puts "No configuration file defined!\n"
          $stdout.puts opt
          exit 1
        end
        @test_identifier = args.shift unless args.empty?
      end
    end

    ##
    # Makes the engine execute either the suite setup specification only (if
    # +--check+ was given as commandline argument) or the entire given
    # specifications otherwise.
    def application_flow
      if @check
        # run just the suite setup test
        if @configuration.suite_setup
          exit @engine.run(@configuration.suite_setup)
        else
          raise Rutema::RutemaError, \
                'There is no suite setup test defined in the configuration.'
        end
      else
        # run everything
        exit @engine.run(@test_identifier)
      end
    end
  end
end
