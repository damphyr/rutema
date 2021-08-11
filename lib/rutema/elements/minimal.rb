#  Copyright (c) 2007-2021 Vassilis Rizopoulos. All rights reserved.

require 'highline'

module Rutema
  ##
  # Module providing a namespace for modules which are used to add to a parsers
  # functionality which can then be utilized in test specifications
  module Elements
    ##
    # Module offering an examplary minimal set of elements for use as steps in
    # test specifications
    module Minimal
      #echo prints a message on the screen:
      # <echo text="A meaningful message"/>
      # <echo>A meaningful message</echo>
      def element_echo step
        step.cmd=Patir::RubyCommand.new("echo"){|cmd| cmd.error="";cmd.output="#{step.text}";$stdout.puts(cmd.output) ;:success}
        return step
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
        return step
      end

      #command executes a shell command
      # <command cmd="useful_command.exe with parameters", working_directory="some/directory"/>
      def element_command step
        raise ParserError,"missing required attribute cmd in #{step}" unless step.has_cmd?
        wd=Dir.pwd
        wd=step.working_directory if step.has_working_directory?
        step.cmd=Patir::ShellCommand.new(:cmd=>step.cmd,:working_directory=>File.expand_path(wd))
        return step  
      end
    end
  end
end
