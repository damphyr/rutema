#  Copyright (c) 2007-2010 Vassilis Rizopoulos. All rights reserved.
$:.unshift File.join(File.dirname(__FILE__),"..","..")
require 'net/smtp'
require 'rutema/reporter'
require 'rutema/specification'
require 'rutema/reporters/text'
require 'mailfactory'

module Rutema
  #The following configuration keys are used by EmailReporter:
  #
  #:server - the smtp server to use
  #
  #:port - the port to use (defaults to 25)
  #
  #:domain - the domain the mail is coming from
  #
  #:sender - the sender of the email (defaults to rutema@domain)
  #
  #:recipients - an array of strings with the recipients of the report emails
  #
  #The :logger key is set by the Coordinator
  #
  #Customization keys:
  #
  #:subject - the string of this key will be prefixed as a subject for the email
  #
  #:verbose - when true, the report contains info on setup and teardown specs. Optional. Default is false
  class EmailReporter
    attr_reader :last_message
    def initialize definition
      #get the logger
      @logger=definition[:logger]
      @logger||=Patir.setup_logger
      #extract the parameters from the definition
      #address and port of the smtp server
      @server=definition[:server]
      @port=definition[:port]
      @port||=25
      #the domain we're coming from
      @domain=definition[:domain]
      #construct the mail factory object
      @mail = MailFactory.new()
      @mail.from = definition[:sender]
      @mail.from||="rutema@#{@domain}"
      @recipients=definition[:recipients]
      #customize
      @subject=definition[:subject]
      @subject||=""
      @footer=definition[:footer]
      @footer||=""
      @verbose=definition[:verbose]
      @verbose||=false
      @logger.info("Reporter '#{self.to_s}' registered")
    end

    def to_s
      list=@recipients.join(', ')
      "EmailReporter - #{@server}:#{@port} from #{@mail.from} to #{list}"
    end
    
    def report specifications,runner_states,parse_errors,configuration
      @mail.subject = "#{@subject}"
      txt=TextReporter.new(:verbose=>@verbose).report(specifications,runner_states,parse_errors,configuration)
      txt<<"\n\n#{@footer}"
      @mail.text = txt 
      begin
        if @recipients.empty?
          @logger.error("No recipients for the report mail")
        else
          #
          #~ if @password
          #~ #if a password is defined, use cram_md5 authentication
          #~ else
          @logger.info("Emailing through #{@server}:#{@port}(#{@domain})")
          Net::SMTP.start(@server, @port, @domain) {|smtp| smtp.send_message(@mail.to_s(),@mail.from,@recipients)}
          #~ end
        end#recipients empty
      rescue
        @logger.debug($!)
        @logger.error("Sending of email report failed: #{$!}")
        @logger.debug("Tried to sent to #{@recipients}")
      end
      @mail.to_s
    end
  end
end