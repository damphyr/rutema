#  Copyright (c) 2008 Vassilis Rizopoulos. All rights reserved.
$:.unshift File.join(File.dirname(__FILE__),"..","..")
require 'rubot/base'
require 'rubot/gems'
module Rubot
  module Overseer
    #Directory where worker definitions are stored
    WORKERS="workers"
    #Directory where rule definitions are stored
    RULES="rules"
    #Directory where sequence definitions are stored
    SEQUENCES="sequences"
    #Worker definition file extension
    WORKER_EXT="worker"
    #Rule definition file extension
    RULE_EXT="rule"
    #Sequence definition file extension
    SEQUENCE_EXT="seq"  

    #Reads the contents of files with a specific extension from a directory
    def self.load_extensions extension_dir, file_extension, logger=nil
      logger = logger || Patir.setup_logger
      extensions=Hash.new
      Rake::FileList["#{extension_dir}/*.#{file_extension}"].each do |f|
        ext_name=File.basename(f).chomp(".#{file_extension}")
        extensions[ext_name]=File.read(f)
      end
      return extensions
    end

    #Is raised when an error is found in an extension file
    class ExtensionError<RuntimeError
    end
    #Provides the evaluation context for rule definition files
    class RuleExtension
      attr_reader :rule
      def initialize base
        @base=base
      end

      def on workers,&block
        return unless block_given?
        if workers.class == Array
          @workers=workers
        else
          @workers=[workers]
        end
        @workers.each{|w| check_worker(w)}
        yield
        raise ExtensionError,"Rule does not trigger any sequence. Use with_sequence" unless @sequence_to_use
        raise ExtensionError,"No match directives - Rule doesn't do anything" unless @rule_parameters.size
        @rule_parameters[:workers]=@workers
        @rule_parameters[:sequence]=@sequence_to_use
        @rule=Rubot::Rule.new(@rule_parameters)
        return @rule
      end

      def with_sequence name
        raise ExtensionError,"No sequence definition for #{name}" unless File.exists?(File.join(@base,SEQUENCES,"#{name}.#{SEQUENCE_EXT}"))
        @sequence_to_use=name
      end

      def match match_hash
        @rule_parameters||=Hash.new
        @rule_parameters.merge!(match_hash)
      end

      def get_binding
        return binding
      end
      private
      def check_worker name
        raise ExtensionError,"No worker definition for #{name}" unless File.exists?(File.join(@base,WORKERS,"#{name}.#{WORKER_EXT}"))
      end
    end
    #Provides the evaluation context for worker definition files
    class WorkerExtension
      attr_reader :worker
      def initialize name
        @name=name
      end
      def get_binding
        binding
      end
      def ip address
        @ip=address
        @worker={:name=>@name,:ip=>address,:port=>@port} if @port
        return @worker
      end
      def port p
        @port=p
        @worker={:name=>@name,:ip=>@ip,:port=>p} if @ip
        return @worker
      end
    end
    #Provides the evaluation context for sequence definition files
    class SequenceExtension
      attr_accessor :request,:sequence
      def initialize(name, request)
        @name=name
        @request = request
        @sequence = Patir::CommandSequence.new(@name)
      end
      def get_binding
        binding
      end
      def shell *args
        return @sequence if args.size == 0
        request=@request
        script = args.first
        name = "#{@name}_cmdstep_#{@sequence.steps.size+1}"
        working_directory = args.size > 1 ? args[1] : nil
        patir_cmd = Patir::ShellCommand.new({ :name => name , :cmd => script , :working_directory => working_directory})
        @sequence.add_step(patir_cmd)
        return @sequence
      end
      
      def ruby &block
        return @sequence unless block_given?
        request=@request
        name = "#{@name}_rubystep_#{@sequence.steps.size+1}"
        ruby_cmd = Patir::RubyCommand.new(name,&block)
        @sequence.add_step(ruby_cmd)
        return @sequence
      end
    end
  end
end