require 'rubot/base'
require 'rubot/model'

require 'patir/command'

module Rubot
  
  # this factory stuff is only to allow to inject different log commands
  # for unit tests. Isn't there an easier way in Ruby?
  class SvnLogCommandFactory
    def createSvnLogCommand url, revision, logger
      SvnLogCommand.new(url, revision, logger)
    end
  end
  
  def self.setSvnLogCommandFactory svnLogCommandFactory
    @svnLogCommandFactory = svnLogCommandFactory
  end
  
  def self.createSvnLogCommand url, revision, logger
    @svnLogCommandFactory = SvnLogCommandFactory.new unless @svnLogCommandFactory
    @svnLogCommandFactory.createSvnLogCommand url, revision, logger
  end
  
  class SvnLogCommand
    def initialize url, revision, logger
      @url = url
      @revision = revision
      @logger = logger
    end
    
    def execute
      start_revision = @revision ? @revision.to_i + 1 : 1
      command = "svn log -v -r #{start_revision}:HEAD #{@url}"
      @logger.debug command
      cmd = Patir::ShellCommand.new({:cmd => command})
      cmd.run
      @logger.error cmd.error if cmd.error
      if (cmd.output && cmd.output.size > 0)
        changes = SvnCmdResultParser.new.parse(cmd.output.split("\n"))
      end
      changes
    end
  end
  
  class PollTask
    attr_reader :logger, :queue_manager, :url, :builder_name
    def initialize params
      @url = params[ :url ]
      @builder_name = params[:builder]
      @logger = params[:logger]
      @queue_manager = params[:queue_manager]
    end
    
    def poll
      @logger.debug "Searching a precedent build request..."
      request = Rubot::Model::Request.latest_request_from_builder @builder_name
      if (request)
        @logger.debug ".. found request with status #{request.status}."
        if request.run && request.run.status =~ /running/
          @logger.info "Not polling subversion log since a build is running."
          return
        # TODO: should the request.status really be pending of the run status is success or failed ?
        elsif !request.run && request.status =~ /pending|running/
          @logger.info "Not polling subversion log due to request status."
          return 
        end
      else
        @logger.debug "... there was none."
      end
      changes = Rubot.createSvnLogCommand(@url, request ? request.revision : nil, @logger).execute
      if !changes.empty? 
        @logger.info("Found #{changes.size} new changes.")
        # :branch ?
        change = Change.new({ :repository => @url, :changeset => changes})
        req=Rubot::BuildRequest.new(@builder_name, change)
        @queue_manager.queue_request(req)
      else 
        @logger.debug("There were no new changes detected.")
      end
    end
    
  end
  
  class ParserContext
    attr_accessor :author, :revision, :comment
    def initialize
      @files = []
    end
    def add_file file
      @files << file
    end
    
    def as_file_changes
      result = []     
      for filename in @files  
        result << FileChange.new(author, filename, comment, revision)
      end
      return result
    end
  end
  
  class SvnCmdResultParser
    
    def parse lines
      result = []
      status = :initial
      file_change = nil
      for line in lines
        log "At status #{status} visiting line: <#{line}>"
        case status
        when :initial
          if line =~ /^[-]+$/ then
            status = :start
            context = ParserContext.new
          end
          
        when :start           
          if line =~ /^r([\d]+)\s\|\s([^\s]*)\s\|.*/
            log "Found Revision : #{$1}"
            context.revision = $1
            context.author = $2
            status = :changes
          elsif line.length == 0
            status = :finished
          else
            throw StandardError.new("Expected revision line") ;
          end 
          
        when :changes
          if line.length == 0
            status = :comment              
          elsif line =~ /[\s]+[A-Z][\s](.*)$/
            log "Found file change: #{$1}"
            context.add_file $1
          end
          
        when :comment
          if line =~ /^[-]+$/ then
            result << context.as_file_changes
            context = ParserContext.new
            status = :start
          else
            context.comment ? context.comment << "\n" + line : context.comment = line 
          end
          
        when :finished
          throw StandardError.new("Found line after end.") ;
          
        else
          throw StandardError.new("Unknown status: #{status}.") ;
          
        end
      end
      return result.flatten 
    end
    
    def log line
      p line
    end
  end
  
end