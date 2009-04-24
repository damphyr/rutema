#  Copyright (c) 2007 Vassilis Rizopoulos. All rights reserved.
$:.unshift File.join(File.dirname(__FILE__),"..")
require 'rubot/version'
require 'rubygems'
require 'patir/base'
module Rubot
  #This class represents a change in a version control system.
  #
  #A Change contains the primary input data for rubot:
  #
  #The repository, branch and set of files that have changed
  #
  #Change might integrate several commits/check-ins
  class Change
    attr_accessor :changeset,:branch,:repository,:timestamp
    
    #Initialization parameters are:
    # :branch - the branch affected by the Change
    # :repository - the repository where the Change originates
    # :changeset - an array of FileChange instances
    # :timestamp - defaults to Time.now
    def initialize params
      @branch=params[:branch]
      @branch||=""
      @repository=params[:repository]
      @repository||=""
      @changeset=params[:changeset]
      @changeset||=Array.new
      @timestamp=params[:timestamp]
      @timestamp||=Time.now
    end

    #Adds a FileChange
    def add_file_change chg
      @changeset<<chg
    end

    #returns an Array with the authors for all FileChanges in this Change
    def authors
      return Array.new if @changeset.empty?
      return @changeset.collect{ |c| c.author }.compact.uniq
    end

    #Returns HEAD if there are no FileChange instances otherwise it will 
    #return the highest revision 
    #(caution: revisions are sorted so textual entries might not bring the expected results)
    def revision
      return "HEAD" if @changeset.empty?
      
      revisions=@changeset.collect{|c| c.revision}.compact.uniq.sort
      numeric_revisions=revisions.collect{|c| c.to_i}.sort
      if numeric_revisions.include?(0)
        return revisions.last
      else
        return numeric_revisions.last.to_s
      end
      
    end
    
    def to_s
      return <<PRETTY
Repository #{@repository}, branch #{@branch}, timestamp #{@timestamp}
File changes:
#{@changeset.collect{|cs| cs.to_s + "\n"}}
PRETTY
    end
  end
  #Represents a changed file providing information on the author, the filename (relative to the repository containing the file)
  #the revision (number or tag) and the log comments
  class FileChange
    attr_accessor :author,:comment,:filename,:revision

    def initialize author,filename,comment,revision
      @author=author
      @filename=filename
      @comment=comment
      @revision=revision
    end
    
    def to_s
    	return "#{@filename}@#{@revision} #{@comment} from #{@author}" 
    end
    
    def ==(other)
      #return false unless FileChange === other
      return self.class == other.class && 
               author == other.author && 
               comment == other.comment &&
               revision == other.revision &&
               filename == other.filename
  # this would be the dynamic version
  #          self.instance_variables == other.instance_variables &&
  #         self.instance_variables.collect {|name| self.instance_eval name} ==
  #          other.instance_variables.collect {|name| other.instance_eval name}
    end
  end
  #Instances of this class are used by the ChangeScheduler to decide which Worker will receive a BuildRequest 
  #based on the current Change event.
  class Rule
    attr_accessor :workers,:pattern,:repository,:branch,:operator,:sequence
    #Keys used in the initialization are:
    #
    #:worker - an Array of the workers triggered by this rule. A least one is required. Specifying more than one worker does not trigger both
    #rather it triggers the first available worker
    #
    #The criteria
    #
    #:pattern - the pattern to match in the FileChange filenames
    #
    #:repository - the repository the Change must match
    #
    #:branch - the branch the Change must match
    #
    #If any of the criteria are nil then they do not influence matching behaviour
    #
    #:operator - this can be :or or :and to define if a Change must match all of the criteria or just one.
    def initialize params
      @workers=params[:workers]
      raise "Why would you define a Rule without a worker?" unless @workers && !@workers.empty?
      @sequence=params[:sequence]
      raise "Won't you give the workers something to do? No sequence defined" unless @sequence
      @pattern=params[:pattern]
      @repository=params[:repository]
      @branch=params[:branch]
      @operator=params[:operator]
      @operator||=:and
    end

    #returns true if the rule matches the passed key values, respecting the rule's operator.
    #
    #The keys are 
    #
    #:repository - matches the value against Rule#repository
    #:branch - matches the value against Rule#branch
    #:filename - matches the value against Rule#pattern
    def matches? params
      matches=process_parameters(params)
      matches.uniq!
      matches.compact!
      case @operator
      when :and
        return matches[0] if matches.size==1
        return false
      when :or
        return matches.include?(true)
      end
    end
    
    def == other
      return true if other.workers.eql?(@workers) &&
                    other.repository==@repository&&
                    other.branch==@branch&&
                    other.pattern==@pattern&&
                    other.operator==@operator
      return false
    end
        
    def to_s
    	return "Repository '#{@repository}', branch '#{@branch}', pattern '#{@pattern}'"
    end
    #Returns the code text that will generate this instance from an extension file.
    #
    #Will only work for the default operator (:and)
    def to_extension
      code="on [\"#{@workers.join("\",\"")}\"] do\n"
      code<<"\tmatch :pattern=>\"#{@pattern}\"\n" if @pattern
      code<<"\tmatch :branch=>\"#{@branch}\"\n" if @branch
      code<<"\tmatch :repository=>\"#{@repository}\"\n" if @repository
      code<<"\twith_sequence \"#{@sequence}\"\nend"
    end
    private
    #returns an array with the match results for all the passed parameters against the rules
    def process_parameters params
      result=Array.new
      if params[:filename]
        result<<process_filename(params[:filename]) 
      else
        result<<false if @pattern && @operator==:and
      end
      if params[:branch]
        result<<process_branch(params[:branch]) 
      else
        result<<false if @branch && @operator==:and
      end
      if params[:repository]
        result<<process_repository(params[:repository]) 
      else
        result<<false if @repository && @operator==:and
      end
      return result
    end
    #see if the filename matches
    def process_filename fname
      return nil unless @pattern
      return true if fname=~/#{@pattern}/
      return false
    end
    #see if the branch matches
    def process_branch branch
      return nil unless @branch
      return true if @branch==branch
      return false
    end
    #see if the repository matches
    def process_repository repo
      return nil unless @repository
      return true if @repository==repo
      return false
    end
  end
  #A BuildRequest is created in the Coordinator and dispatched by the Dispatcher.
  #
  #One of the associated workers will then perform a build based on this request.
  class BuildRequest
    attr_accessor :worker,:command_sequence,:change,:timestamp,:request_id
    def initialize worker,change=nil
      @timestamp=Time.now
      @worker=worker
      @change=change
    end
  end
  
end
  
