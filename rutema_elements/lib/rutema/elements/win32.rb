#  Copyright (c) 2008 Vassilis Rizopoulos. All rights reserved.
require 'rubygems'
require 'patir/command'
require 'rutema/system'

module Rutema
  module Elements
    #Elements to drive Microsoft's SQLServer
    module SQLServer
      #Calls sqlcmd.
      #
      #Requires the script attribute pointing to the SQL script to execute. Path can be relative to the specification file.
      #===Configuration
      #Requires a configuration.tool entry with :name=>"sqlcmd"
      #and a :configuration entry pointing to a hash containing the configuration parameters.
      #Configuration parameters are:
      # :host - the host to run the command against (sqlcmd -H)
      # :server - the SQLServer (named instance) (sqlcmd -S)
      # :username - the SQLServer user (sqlcmd -U)
      # :password - (sqlcmd -P)
      # :script_root - The path relative to which pathnames for scripts are calculated. If it's missing paths are relative to the specification file. Optional
      #===Example Configuration Entry
      # configuration.tool={:name=>"sqlcmd",:configuration=>{:host=>"guineapig",:server=>"DB",:user=>"foo",:password=>"bar"}}
      #
      #===Extras
      #Not defining any options (e.g. not defining the configuration.tool entry) results in the script running locally without options
      #
      #The configuration options can be overriden by element attributes (host,server,username etc.).
      #Additionally the following attributes can be defined:
      # database - the database to run the script against ( sqlcmd -d )
      # level - Sets the errorlevel for the script (sqlcmd -V)
      #
      #===Example Elements
      # <sqlcmd script="some.sql"/>
      # <sqlcmd script="some.sql" host="localhost"/> - overriding host
      # <sqlcmd script="some.sql" database="MyDB" level="11"/> - hypersensitive error checking and explicitly executed on MyDB
      def element_sqlcmd step
        raise Rutema::ParserError,"Missing required script attribute in sqlcmd step" unless step.has_script?
        cfg=@configuration.tools.sqlcmd[:configuration].dup if @configuration.tools.sqlcmd && @configuration.tools.sqlcmd[:configuration]
        cfg||=Hash.new
        root_path=script_root_path(cfg,step)
        cfg[:script]=adjust_with_root_path(step.script,root_path,step)
        #check for overrides
        cfg[:host] = step.host if step.has_host?
        cfg[:server] = step.host if step.has_server?
        cfg[:username] = step.host if step.has_username?
        cfg[:password] = step.host if step.has_password?
        #add the optional attributes
        cfg[:database] = step.database if step.has_database?
        cfg[:level] = step.level if step.has_level?
        #get the command object
        step.cmd=sqlcmd_command(cfg)
        return step
      end
      
      #Calls vsdbcmd to deploy a database schema
      #
      #Requires the dbschema attribute pointing to the dbschema file to deploy. 
      #
      #Paths can be relative to the specification file
      #===Configuration
      #Requires a configuration.tool entry with :name=>"vsdbcmd" 
      #and a :configuration entry pointing to a hash containing the configuration parameters.
      #Configuration parameters are:
      # :path - the path to the vsdbcmd.exe
      # :cs - the connection string to use
      # :manifest - path to the depploymanifest file to use. If not present then a manifest attribute is expected. 
      # :overrides - Optional. Should be a string containing parameters that override vsdbcmd parameters in the format expected by vsdbcmd
      # :script_root - The path relative to which pathnames for scripts are calculated. If it's missing, paths are relative to the specification file. Optional
      #all configuration options apart from :path can be overriden in the element
      #===Example Configuration Entry
      # configuration.tool={:name=>"vsdbcmd",:configuration=>{:path=>"c:/tools/db/vsdbcmd.exe",:cs=>"Data Source=(local);;Initial Catalog=YourDB;Integrated Security=True":overrides=>"/p:AlwaysCreateNewDatabase=True"}}
      #===Extras
      #When overriding the :manifest configuration the path to the file can be relative to the specification file or the :script_root path if defined
      #
      #A .deploymanifest is required because of the number of possible parameters that can be defined in it and it's dependent files. Making every parameter available in the configuration will result in nothing but a mess. In every case a database project in Visual Studio will create a manifest file.
      #
      #Use the :overrides key to override parameter values and provide extra command line parameters. The :overrides value must be in valid vsdbcmd format (see examples)
      #
      #Defining paths in :overrides and handling paths defined in the .deploymanifest can be tricky: All paths will be relative to the specification file.
      #===Example Elements
      # <vsdbcmd dbschema="../yourdb.dbschema"/>
      # <vsdbcmd dbschema="../yourdb.dbschema" overrides="/p:AlwaysCreateNewDatabase=False /p:BlockIncrementalDeploymentIfDataLoss=True"/>
      # <vsdbcmd dbschema="../yourdb.dbschema" overrides="/p:AlwaysCreateNewDatabase=False /DeploymentScriptFile:\"somefile.sql\""/>
      def element_vsdbcmd step
        raise Rutema::ParserError,"Missing tool configuration for vsdbcmd (no configuration.tool entry)" unless @configuration.tools.vsdbcmd && @configuration.tools.vsdbcmd[:configuration]
        raise Rutema::ParserError,"Missing required dbschema attribute in vsdbcmd step" unless step.has_dbschema?
        cfg=@configuration.tools.vsdbcmd[:configuration].dup
        path_to_util=File.expand_path(cfg[:path])
        raise Rutema::ParserError,"Cannot find vsdbcmd in '#{path_to_util}'" unless File.exists?(path_to_util)
        cfg[:dsp]||="sql"
        root_path=script_root_path(cfg,step)
        cfg[:dbschema]=adjust_with_root_path(step.dbschema,root_path,step)
        #check the manifest and handle also the value from a possible attribute.
        #if both are missing than it's an error
        manifest=cfg[:manifest]
        manifest=step.manifest if step.has_manifest?
        raise Rutema::ParserError,"No manifest file defined for #{step.step_type} (wether in the configuration or as an attribute)" unless manifest
        cfg[:manifest]=adjust_with_root_path(manifest,root_path,step)
        #do the same for connection string
        connection_string=cfg[:cs]
        connection_string=step.connection_string if step.has_connection_string?
        raise Rutema::ParserError,"No connection string defined for #{step.step_type} (wether in the configuration or as an attribute)" unless connection_string
        cfg[:cs]=connection_string
        #optional overrides
        if step.has_overrides?
          cfg[:overrides]=step.overrides
        end
        #assign the command
        step.cmd=vsdbcmd_command(cfg)
        return step
      end
      private
      def script_root_path cfg,step
        root_path=cfg[:script_root]
        if step.has_script_root?
          root_path=step.script_root
        else
          root_path||=Dir.pwd
        end
        return root_path
      end
      #checks the path to use as script root
      def adjust_with_root_path filename,root_path,step
        if File.exists?(filename)
          return File.expand_path(filename)
        else
          #see if there is a script root directory
          raise Rutema::ParserError,"Root directory '#{root_path}' for #{step.step_type} does not exist. Check the configuration or the override in the affected scenario" unless File.exists?(root_path)
          script_path=File.expand_path(File.join(root_path,filename))
          raise Rutema::ParserError,"Cannot find file '#{script_path}' specified in #{step.step_type}" unless File.exists?(script_path)
          return script_path
        end
      end
      #Returns the Patir::ShellCommand with the correct commandline
      def sqlcmd_command cfg
        cmdline="sqlcmd -i \"#{File.expand_path(cfg[:script]).gsub("/","\\\\")}\" -b "
        cmdline<<" -H #{cfg[:host]}" if cfg[:host] && cfg[:host]!="local"
        cmdline<<" -S #{cfg[:server]}" if cfg[:server]
        cmdline<<" -U #{cfg[:username]}" if cfg[:username]
        cmdline<<" -P #{cfg[:password]}" if cfg[:password]
        cmdline<<" -d #{cfg[:database]}" if cfg[:database]
        cmdline<<" -V#{cfg[:level]}" if cfg[:level]
        #make sure the script executes at the directory where it is.
        return Patir::ShellCommand.new(:cmd=>cmdline,:working_directory=>File.dirname(File.expand_path(cfg[:script])))
      end
      #Returns the Patir::ShellCommand with the correct commandline
      def vsdbcmd_command cfg
        path_to_util=File.expand_path(cfg[:path])
        dbschema=File.expand_path(cfg[:dbschema]).gsub("/","\\\\")
        manifest=File.expand_path(cfg[:manifest]).gsub("/","\\\\")
        cmdline="#{path_to_util} /a:Deploy /dsp:#{cfg[:dsp]}  /dd /model:\"#{dbschema}\" /manifest:\"#{manifest}\" /cs:\"#{cfg[:cs]}\" #{cfg[:overrides]}"
        @logger.debug("Parsed vsdbcmd call as '#{cmdline}'")
        #make sure the script executes at the specification directory.
        return Patir::ShellCommand.new(:cmd=>cmdline)
      end
    end
    #Elements to drive MSTest
    module MSTest
      #Calls an MSTest assembly.
      #
      #Requires the attribute assembly pointing to the assembly to execute. Path can be relative to the specification file.
      #===Configuration
      #Requires a configuration.tool entry with :name=>"mstest"
      #and a :configuration entry pointing to a hash containing the configuration parameters.
      # 
      #Configuration parameters are:
      # :path - the path to the mstest utility. Required
      # :shared_path - a {:local=>"localpath",:share=>"sharepath"} entry. Optional
      # :assembly_root - the path relative to which the assembly paths are calculated. If it's not defined then the paths are calculated relative to the specification file. Optional 
      #===Example Configuration Entry
      # configuration.tool={:name=>"mstest",:configuration=>{:path=>"/to/mstest.exe",assembly_root=>"c:/assemblies"}}
      #
      #===Extras
      #The shared_path hash is a workaround for calling assemblies when the current working directory is on a shared drive 
      #(i.e. when running certain tasks in a TFS build)
      #
      #An example will illustrate it's usage better:
      #
      #{:share=>"//host/tests",:local=>"c:/tests"} will result in :share being substituted with :local on the assembly pathname
      #so \\\\\\host\\\\tests\\\\assembly.dll becomes c:\\\\tests\\\\assembly.dll
      #
      #Note that entries should be defined with '/' instead of '\\\\'.
      #===Examples
      # <mstest assembly="tests.dll"/>
      def element_mstest step
        raise Rutema::ParserError,"Missing required attribute 'assembly'" unless step.has_assembly?
        raise Rutema::ParserError,"Missing tool configuration for mstest (no configuration.tool entry)" unless @configuration.tools.mstest && @configuration.tools.mstest[:configuration]
        cfg=@configuration.tools.mstest[:configuration].dup
        path_to_util=cfg[:path]
        raise Rutema::ParserError,"Cannot find mstest in '#{path_to_util}'" unless File.exists?(path_to_util)
        if step.has_assembly_root?
          cfg[:assembly_root]=step.assembly_root
        else
          cfg[:assembly_root]=Dir.pwd
        end
        #icalculate the paths relative to the assembly_root
        assembly_path=adjust_with_root_path(step.assembly,cfg[:assembly_root],step)
        #check to see if we apply the workaround
        shared_path=cfg[:shared_path]
        if shared_path
          raise Rutema::ParserError,"Missing :share key for shared_path configuration" unless shared_path[:share]
          raise Rutema::ParserError,"Missing :local key for shared_path configuration" unless shared_path[:local]
          @logger.debug("Assembly path is '#{assembly_path}'")
          @logger.debug("Shared path manipulation (#{shared_path[:share]}=>#{shared_path[:local]}")
          assembly_path.gsub!(shared_path[:share],shared_path[:local])
          @logger.debug("Assembly path is now '#{assembly_path}'")
        end
        #make the path windows compatible
        assembly_path.gsub!('/',"\\\\")
        #create the command line and the command instance
        cmdline="\"#{path_to_util}\" /testcontainer:\"#{assembly_path}\""
        @logger.debug("Parsed mstest call as '#{cmdline}'")
        step.cmd=Patir::ShellCommand.new(:cmd=>cmdline,:working_directory=>File.dirname(assembly_path))
        return step
      end
      private
      #checks the path to use as script root
      def adjust_with_root_path filename,root_path,step
        if File.exists?(filename)
          return File.expand_path(filename)
        else
          #see if there is a script root directory
          raise Rutema::ParserError,"Root directory '#{root_path}' for #{step.step_type} does not exist. Check the configuration or the override in the affected scenario" unless File.exists?(root_path)
          script_path=File.expand_path(File.join(root_path,filename))
          raise Rutema::ParserError,"Cannot find file '#{script_path}' specified in #{step.step_type}" unless File.exists?(script_path)
          return script_path
        end
      end
    end
    #Elements to drive IIS
    module IIS
      #Resets an IIS server
      #===Configuration
      #Uses a configuration.tool entry with :name=>"iisreset"
      #and a :configuration entry pointing to a hash containing the configuration parameters.
      #
      #Configuration parameters are:
      # :server - the IIS to reset     
      #===Example Configuration Entry
      # configuration.tool={:name=>"iisreset",:configuration=>{:server=>"localhost"}}
      #
      #===Extras
      #The configuration options can be overriden by element attributes (i.e. server="localhost" etc.).
      #Additionally the following attributes can be defined:
      # start - when present the element will perform an iisreset /start
      # stop - when present the element will perform an iisreset /stop
      #
      #===Examples
      # <iisreset/> - resets according to the configuration
      # <iisreset start="true"/> - starts the server defined in the configuration
      # <iisreset server="localhost" stop="true"/> - stops localhost 
      def element_iisreset step
        cfg=@configuration.tools.iisreset[:configuration].dup if @configuration.tools.iisreset && @configuration.tools.iisreset[:configuration] 
        cfg||=Hash.new
        cfg[:server]=step.server if step.has_server?
        raise Rutema::ParserError,"No server attribute and no configuration present for iisreset step" unless cfg[:server]
        raise Rutema::ParserError,"Only one of 'stop' or 'start' can be defined in an iisreset step" if step.has_stop? && step.has_start?
        cfg[:stop]=true if step.has_stop?
        cfg[:start]=true if step.has_start?
        step.cmd=iisreset_command(cfg)
        return step
      end
      private
      #returns the Patir::ShellCommand with the correct commandline
      def iisreset_command cfg
        cmdline="iisreset "
        cmdline<<" /STOP" if cfg[:stop]
        cmdline<<" /START" if cfg[:start]
        cmdline<<" #{cfg[:server]}"
        
        return Patir::ShellCommand.new(:cmd=>cmdline)
      end
    end
  end
end