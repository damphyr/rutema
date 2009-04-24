#  Copyright (c) 2008 Vassilis Rizopoulos. All rights reserved.
require 'rubygems'
require 'patir/command'
require 'rutema/system'
require 'open-uri'
module Rutema
  #The Elements module provides the namespace for the various functional modules
  module Elements
    module Version
      MAJOR=0
      MINOR=1
      TINY=4
      STRING=[ MAJOR, MINOR, TINY ].join( "." )
    end
    module Web
      #Performs an HTTP GET for the given URL.
      #
      #It's usually used as a quick "it's alive" sign. It can also be used as a smart wait when restarting web servers.
      #===Configuration
      #No configuration necessary
      #
      #===Extras
      #Requires the attribute address pointing to the URL to fetch
      #
      #Optionally the following attributes can be defined: 
      # retry - sets the number of times to attempt to fetch the URL before failing
      # pause - sets the duration of sleep between retry attemps (in seconds) 
      #
      #===Example Elements
      # <get_url address="http://localhost" retry="5" pause="3"/>
      def element_get_url step
        address=step.address if step.has_address?
        address||=@configuration.tools.get_url[:configuration][:address] if @configuration.tools.get_url && @configuration.tools.get_url[:configuration] 
        raise Rutema::ParserError,"No address attribute and no configuration present for get_url step" unless address
        retries= step.retry.to_i if step.has_retry?
        retries||=0
        pause_time =  step.pause.to_i if step.has_retry? && step.has_pause?
        uri = URI.parse(step.address)
        step.cmd=url_command(uri,retries,pause_time)
        return step
      end
      
      private
      def url_command url,retries,pause_time
        Patir::RubyCommand.new("get_url",File.expand_path(File.dirname(__FILE__))) do |cmd|
          cmd.output<<"Opening URL #{url.to_s}"
          tries=0
          suc=get_url(url,cmd)
          while !suc && tries < retries
            tries+=1
            sleep pause_time if pause_time
            suc=get_url(url,cmd)
          end
          raise "get_url failed" unless suc
        end
      end
      
      def get_url url,cmd
        begin
          #get the base URL to start the server
          cmd.output<<"\n#{url.read}"
          return true
        rescue Timeout::Error, OpenURI::HTTPError, Errno::ECONNREFUSED
          cmd.error<<$!.message
          cmd.error<<"\n"
          return false
        end
      end
    end
    module Standard
      #Waits for a while
      #
      #===Configuration
      #No configuration necessary
      #
      #===Extras
      #Requires the attribute timeout setting the time to wait in seconds
      #
      #===Example Elements
      # <wait timeout="5"/>
      def element_wait step
         raise Rutema::ParserError,"No timeout attribute for wait step" unless step.has_timeout?
         step.cmd=Patir::RubyCommand.new("wait",File.expand_path(File.dirname(__FILE__))) do |cmd|
           sleep step.timeout
         end
         return step
      end
      #Fails a test
      #
      #===Configuration
      #No configuration necessary
      #
      #===Extras
      #The attribute text can be used to set the error message for the step
      #
      #===Example Elements
      # <fail/>
      # <fail text="On Purpose!"/>
      def element_fail step
        step.cmd=Patir::RubyCommand.new("fail",File.expand_path(File.dirname(__FILE__))) do |cmd|
           msg="Fail! "
           msg<<step.text if step.has_text?
           raise msg
         end
         return step
      end
    end
  end
end