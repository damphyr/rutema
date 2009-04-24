require 'net/smtp'
require 'mailfactory'
require 'patir/base'
module Rubot
  module StatusHandlers
    #EmailStatusHandler sends email notification when a build is finished.
    #
    #It basically has three notification settings: full, warning and failure.
    #
    #The notification setting is set using the :notification configuration key
    #
    #:notification => :all sends an email everytime a build is finished regardless of result 
    #
    #:notification => :warning sends an email everytime a build produces warnings or fails
    #
    #:notification => :error sends an email everytime a build fails (default)
    #
    #The following configuration keys are also used by EmailStatusHandler:
    #
    #:server - the smtp server to use
    #
    #:domain - the domain to append to non-valid recipient string
    #
    #:recipients - an array of strings with the default recipients of the status emails  (if no recipients are set then emails are sent only to change authors)
    #
    #:mail_map - a hash containing user=>email_address mapping for mapping change author names to email addresses.
    #
    #When sending an email, the EmailStatusHandler wil go through the recipients list and check if it contains valid email addresses.
    #
    #If not, then it will try to get the addresses from the mail_map Hash and if not found it will append :domain to the recipient string and try to send the email.
    #
    #If the received status has an associated change, the handler will also send email to the author of that change (always according to the :notification mode)
    class EmailStatusHandler
      attr_reader :last_message
      def initialize definition
        #get the logger
        @logger=definition[:logger]
        @logger||=Patir.setup_logger
        #extract the parameters from the definition
        #type of notification to use
        @notification=definition[:notification]
        #defaults to :error
        @notification||=:error
        #address and port of the smtp server
        @server=definition[:server]
        @port=definition[:port]
        @port||=25
        #the domain we're coming from
        @domain=definition[:domain]
        #construct the mail factory object
        @mail = MailFactory.new()
        @mail.from = definition[:sender]
        @mail.from||="rubot@#{@domain}"
        #get the mail mappings
        @mail_map=definition[:mail_map]
        #get the standard recipients
        @recipients=determine_recipients(definition[:recipients])
        #this is a way to test without sending
        @dummy=true if definition[:dummy]
        @logger.info(self.to_s)
      end

      def handle build_status
        @logger.debug("Handling #{build_status}")
        #check if it finished
        if !build_status.running? && build_status.status!=:not_executed
          case @notification
          when :all
            #just send it
            send_notification(build_status)
          when :warning
            #only if a warning (or failure) was issued
            send_notification(build_status) unless build_status.success?
          when :error
            #only when failed
            send_notification(build_status) if :error==build_status.status
          end
        else
          @logger.debug("Build not finished")
        end
        #else don't do anything
      end

      def to_s
        list=@recipients.join(', ')
        "#{@server}:#{@port} from #{@domain} to #{list}"
      end
      private
      def send_notification build_status
        @last_message=nil
        @logger.info("Sending email about #{build_status}")
        mail_to=@recipients
        #TODO: find if there is a change associated with the build and get the author and add it to the recipient list
        # mail_to+=determine_recipients
        @mail.to=mail_to
        @mail.subject = "[RUBOT] #{build_status.sequence_id}:#{build_status.sequence_name}  #{build_status.status}"
        @mail.text = build_status.summary+"\nRunning on #{build_status.rubot_slave}"
        begin
          if mail_to.empty?
            @logger.error("No recipients for the status mail")
          else
            #
            #~ if @password
            #~ #if a password is defined, use cram_md5 authentication
            #~ else
            Net::SMTP.start(@server, @port, @domain) {|smtp| smtp.sendmail(@mail.to_s(),@mail.from,mail_to)} unless @dummy
            @last_message=@mail.to_s
            #~ end
          end#recipients empty
        rescue
          @logger.error("Sending of email report failed: #{$!}")
        end
      end

      #It will go through the recipients list and sanitize it (perform the mapping if mail_map is present, add the domain etc)
      #
      #Returns the correct recipients list to use
      def determine_recipients recipients
        reps=Array.new
        if recipients.kind_of?(Array)
          recipients.each do |rep|
            #is it a valid email?
            if email_valid?(rep)
              reps<<rep
            else
              @logger.debug("'#{rep}' is not a valid email address")
              #look for mapping
              if @mail_map
                mapped_to=@mail_map[rep]
                @logger.debug("mapped #{rep} to #{mapped_to}") if mapped_to
              end
              #if no mapping is present, then just add the domain
              mapped_to||="#{rep}@#{@domain}"
              #add it to the list
              reps<<mapped_to
            end
          end
        else
          @logger.error("Invalid recipient list (NotAnArray): #{recipients}")
        end
        return reps
      end

      def email_valid? address
        return true if address.include?("@")
        return false
      end
    end
  end
end