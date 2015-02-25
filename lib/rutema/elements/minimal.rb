#  Copyright (c) 2007-2011 Vassilis Rizopoulos. All rights reserved.

module Rutema
  #The Elements module provides the namespace for the various modules adding parser functionality
  module Elements
    #Minimal offers a minimal(chic) set of elements for use in specifications
    #
    #These are:
    # echo
    # command
    # prompt
    module Minimal
      #echo prints a message on the screen:
      # <echo text="A meaningful message"/>
      # <echo>A meaningful message</echo>
      def element_echo step
        step.cmd=Patir::RubyCommand.new("echo"){|cmd| cmd.error="";cmd.output="#{step.text}";$stdout.puts(cmd.output) ;:success}
      end
      #prompt asks the user a yes/no question. Answering yes means the step is succesful.
      # <prompt text="Do you want fries with that?"/>
      #
      #A prompt element automatically makes a specification "attended"
      def element_prompt step
         step.attended=true
         step.cmd=Patir::RubyCommand.new("prompt") do |cmd|  
          cmd.output=""
          cmd.error=""
          if HighLine.new.agree("#{step.text}")
            step.output="y"
          else
            raise "n"
          end#if
        end#do rubycommand
      end
      #command executes a shell command
      # <command cmd="useful_command.exe with parameters", working_directory="some/directory"/>
      def element_command step
        raise ParserError,"missing required attribute cmd in #{step}" unless step.has_cmd?
        wd=Dir.pwd
        wd=step.working_directory if step.has_working_directory?
        step.cmd=Patir::ShellCommand.new(:cmd=>step.cmd,:working_directory=>File.expand_path(wd))      
      end
    end
  end
end