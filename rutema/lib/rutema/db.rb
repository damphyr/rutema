#  Copyright (c) 2008 Vassilis Rizopoulos, Markus Barchfeld. All rights reserved.
$:.unshift File.join(File.dirname(__FILE__),"..")

module Rutema
  
  class SQLiteConnection
    def initialize logger, database
      @logger=logger
      @database=database
    end
    
    def adapter
         "sqlite3"
    end
    
    def connected?
      result = ActiveRecord::Base.connected?
      @logger.debug "Connected " + result.to_s
      return result
    end
    
    def connect
      ActiveRecord::Base.establish_connection(:adapter=>adapter, :database=>@database )
      @logger.warn("'#{@database}' does not exist") if !(File.exists?(@database)) && @database!=":memory:"
      connected?
    end
    
    def migrate
      return if File.exists?(@database)
      @logger.info "Migrating DB"
      Model::Schema.migrate(:up) 
    end
  end
  
  class H2Connection
    def initialize logger, database
      @logger=logger
      @database=database
    end
    
    def adapter
      "jdbch2"
    end
    def port
      7098
    end
    def base_dir
      "/"
    end
    def connected?
      begin
        ActiveRecord::Base.retrieve_connection
      rescue RuntimeError
      end
      result = ActiveRecord::Base.connected?
      @logger.debug "Connected " + result.to_s
      result
    end
    
    def connect
      connect_server
      if not connected?
        start_server
        connect_server
      end
      connected?
    end
    
    def connect_server
      url = server_url
      @logger.info "Connecting to " + server_url
      ActiveRecord::Base.establish_connection(:adapter=>adapter, 
                                              :driver => 'org.h2.Driver', 
      :url=> server_url)
    end
    
    def server_url
      # database is supposed to be an absolute path
      "jdbc:h2:tcp://localhost:" + port.to_s + @database
    end
    
    # Start a h2 server to allow mixed mode accessing. 
    def start_server
      args = ["-tcpPort", port.to_s, "-baseDir", base_dir]
      @logger.info "Starting H2 server using arguments " + args.join(" ")
      require 'jdbc/h2'
      Rutema.includeJava
      org.h2.tools.Server.createTcpServer(args.to_java(:string)).start()
    end
    
    def migrate
      return if File.exists?("#{@database}.data.db")
      @logger.info "Migrating DB"
      Model::Schema.migrate(:up) 
    end
    
    
  end
  
  
  #Exception occuring when connecting to a database
  class ConnectionError<RuntimeError
  end
  #Establishes an ActiveRecord connection
  def self.connect_to_ar database,logger,perform_migration=true
    raise ConnectionError,"No database source defined in the configuration" unless database
    logger.debug("Connecting to #{database}")
    conn = connection(logger, database)
    conn.connect
    conn.migrate if perform_migration
  end
  
  private 
  
  @@connection=nil
  
  def self.connection logger, database
    if not @@connection
      @@connection = RUBY_PLATFORM =~ /java/ ? H2Connection.new(logger, database) : SQLiteConnection.new(logger, database)
    end
    @@connection
  end
  
  def self.includeJava
    # "undefined method 'include'" in instance method
    include Java if RUBY_PLATFORM =~ /java/
  end
end