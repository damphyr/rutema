require  'optparse'
require_relative "core/configuration"
require_relative "core/engine"

module Rutema
  #Parses the commandline, sets up the configuration and launches Rutema::Engine
  class App
    def initialize command_line_args
      parse_command_line(command_line_args)
      begin
        @configuration=Rutema::Configuration.new(@config_file)
        @configuration.context[:config_file]=File.basename(@config_file)
        unless @silent
          @configuration.reporters||=[]
          @configuration.reporters<<{:class=>Rutema::Reporters::Console}
        end
        Dir.chdir(File.dirname(@config_file)) do 
          @engine=Rutema::Engine.new(@configuration)
          application_flow
        end
      end
    end
    private
    def parse_command_line args
      args.options do |opt|
        opt.on("rutema v#{Version::STRING}")
        opt.on("Options:")
        opt.on("--config FILE", "-c FILE",String,"Loads the configuration from FILE") { |config_file| @config_file=config_file}
        opt.on("--check","Runs just the check test"){@check=true}
        opt.on("--step","Runs test cases step by step"){@step=true}
        opt.on("-v", "--version","Displays the version") { $stdout.puts("rutema v#{Version::STRING}");exit 0 }
        opt.on("--help", "-h", "-?", "This text") { $stdout.puts opt; exit 0 }
        opt.on("--silent","Suppresses the Console reporter") { @silent=true}
        opt.on("You can provide a specification filename in order to run a single test")
        opt.parse!
        #and now the rest
        unless @config_file
          puts "No configuration file defined!\n"
          $stdout.puts opt 
          exit 1
        end
        if !args.empty?
          @test_identifier=args.shift
        end
      end
    end
    def application_flow
      if @check
        #run just the check test
        if @configuration.check
          @engine.run(@configuration.check)
        else
          raise Rutema::RutemaError,"There is no check test defined in the configuration."
        end
      else
        #run everything
        @engine.run(@test_identifier)
      end
    end
  end
end