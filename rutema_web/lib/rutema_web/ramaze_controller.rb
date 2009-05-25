#  Copyright (c) 2008 Vassilis Rizopoulos. All rights reserved.
$:.unshift File.join(File.dirname(__FILE__),"..")
require 'rutema_web/gems'
require 'rutema_web/ruport_formatter.rb'
require 'rutema_web/model'
require 'rutema/system'

module Rutema
  module UI
    #Helper methods that create HTML snippets
    module ViewUtilities
      #image filename to use for succesfull scenarios
      IMG_SCE_OK="/images/run_ok.png"
      #image filename to use for failed scenarios
      IMG_SCE_ERROR="/images/run_error.png"
      #image filename to use for unexecuted scenarios
      IMG_SCE_WARN="/images/run_warn.png"
      #image filename to use for succesfull steps
      IMG_STEP_OK="/images/step_ok.png"
      #image filename to use for failed steps
      IMG_STEP_ERROR="/images/step_error.png"
      #image filename to use for unexecuted steps
      IMG_STEP_WARN="/images/step_warn.png"
      #Time format to use for the start and stop times
      TIME_FORMAT="%d/%m/%Y\n%H:%M:%S"
      #The left arrow
      IMG_LEFT="/images/left.png"
      #The right arrow
      IMG_RIGHT="images/right.png"
      # returns the image tag appropriate for the given status
      def status_icon status
        return case status
        when :warning ,"not_executed" 
          "<img src=\"#{IMG_STEP_WARN}\" align=\"center\"/>"
        when :success, "success"
          "<img src=\"#{IMG_STEP_OK}\" align=\"center\"/>"
        when :error, "error"
          "<img src=\"#{IMG_STEP_ERROR}\" align=\"center\"/>"
        else
          "<img src=\"#{IMG_STEP_WARN}\" align=\"center\"/>"
        end
      end
      # Returns a string with the correct time format for display
      def time_formatted time
        time.strftime(TIME_FORMAT)
      end
      #Returns the URL of details page for a run
      def run_url run
        "/run/#{run.id}"
      end

      def run_summary r
        Ramaze::Log.debug("Summary snippet for #{r}") if @logger
        msg="#{run_link(r)}"
        if r.context.is_a?(Hash)
          msg<<" started at #{time_formatted(r.context[:start_time])}"
        end
        return msg
      end

      def run_link r
        "<a class=\"smallgreytext\" href=\"#{run_url(r)}\">Run #{r.id}</a>"
      end
      def cfg_link cfg
        "<a class=\"smallgreytext\" href=\"/statistics/config_report/#{cfg}\">#{cfg}</a>"
      end
      #will render a hash in a table of key||value rows 
      def context_table context
        ret=""
        if context.is_a?(Hash)
          ret="<p>"
          ret<<"Run configured from #{context[:config_file]}<br/>" if context[:config_file]
          ret<<"Started at #{time_formatted(context[:start_time])}<br/>"
          ret<<"Ended at #{time_formatted(context[:end_time])}<br/>"
          ret<<"Total duration #{context[:end_time]-context[:start_time]} seconds</p>"
        end
        return ret
      end

      #returns the pagination HTML for runs
      def run_page_link page_number,page_total
        ret=""
        unless page_total==1
          ret<<"<a href=\"/runs/#{page_number-1}\">Previous</a>" unless page_number==0
          ret<<" | Page #{page_number+1}"
          ret<<" | <a href=\"/runs/#{page_number+1}\">Next</a>" unless page_number==page_total-1
        end
        return ret
      end
      #returns the pagination HTML for scenarios
      def scenario_page_link page_number,page_total
        ret=""
        unless page_total==1
          ret<<"<a href=\"/scenarios/#{page_number-1}\">Previous</a>" unless page_number==0
          ret<<" | Page #{page_number+1}"
          ret<<" | <a href=\"/scenarios/#{page_number+1}\">Next</a>" unless page_number==page_total-1
        end
        return ret
      end

      #Gives the HTML to use for the status column of a scenario list
      def scenario_status r
        img_src=IMG_SCE_WARN
        img_src=IMG_SCE_OK if "success"==r.status
        img_src=IMG_SCE_ERROR if "error"==r.status
        "<img src=\"#{img_src}\" align=\"center\"/>"
      end

    end

    #Contains all the settings that control the display of information for RutemaWeb's controllers 
    module Settings
      @@rutemaweb_settings||=Hash.new
      #Set to true to show all setup and teardown scenarios
      def show_setup_teardown= v
        @@rutemaweb_settings[:show_setup_teardown]= v
      end 
      
      def show_setup_teardown?
        return @@rutemaweb_settings[:show_setup_teardown]
      end
    end
    #Sets the values we need for public and view directories
    def self.ramaze_settings
      Ramaze::Global.public_root = File.expand_path(File.join(File.dirname(__FILE__),"public"))
      Ramaze::Global.view_root = File.expand_path(File.join(File.dirname(__FILE__),"view"))
    end

    class MainController < Ramaze::Controller
      include ViewUtilities
      include Settings
      map '/'
      engine :Erubis
      layout :layout
      #The number of items to show in lists
      PAGE_SIZE=10

      def index
        @title="Rutema"
        @panel_content=panel_runs
        @content_title="Welcome to Rutema"
        @content="<p>This is the rutema web interface.<br/>It allows you to browse the contents of the test results database.</p><p>Currently you can view the results for each separate run, the results for a specific scenario (a complete list of all steps executed in the scenario with standard and error output logs) or the complete execution history of a scenario.</p><p>The panel on the left shows a list of the ten most recent runs.</p>"
      end
      #Displays a paginated list of all runs
      def runs page=0
        @title="All runs"
        @content_title="Runs"
        @content=""
        dt=[]
        total_pages=(Rutema::Model::Run.count/PAGE_SIZE)+1
        page_number=validated_page_number(page,total_pages)

        runs=Rutema::Model::Run.find_on_page(page_number,PAGE_SIZE)
        runs.each do |r| 
          dt<<[status_icon(r.status),run_summary(r),r.config_file]
        end
        @content<< Ruport::Data::Table.new(:data=>dt,:column_names=>["status","description","configuration"]).to_html
        @content<<"<br/>"
        @content<<run_page_link(page_number,total_pages)
        return @content
      end
      #Displays the details of a run
      #
      #Routes to /runs if no id is provided
      def run run_id=""
        @panel_content=nil
        if !run_id.empty?
          @panel_content=panel_runs
          @title="Run #{run_id}"
          @content_title="Summary of run #{run_id}"
          @content=single_run(run_id)
        else
          runs
        end
      end

      #Displays a paginated list of scenarios
      def scenarios page=0
        @title="All scenarios"
        @content_title="Scenarios"
        @content=""
        @panel_content=panel_runs
        runs=Hash.new
        #find which runs contain each scenario with the same name
        Ramaze::Log.debug("Getting the runs for each scenario")
        conditions="name NOT LIKE '%_teardown' AND name NOT LIKE '%_setup'"
        Rutema::Model::Scenario.find(:all, :conditions=>conditions).each do |sc|
          nm=sc.name
          runs[nm]||=[]
          runs[nm]<<sc.run.id
        end
        #the size of the hash is also the number of unique scenario names
        total_pages=(runs.size / PAGE_SIZE)+1
        page_number=validated_page_number(page,total_pages)
        Ramaze::Log.debug("Getting scenarios for page #{page_number}")
        scens=Rutema::Model::Scenario.find_on_page(page_number,PAGE_SIZE,conditions)
        #and now build the table data
        dt=Array.new
        scens.each do |sc|
          nm=sc.name
          #sort the run ids
          runs[nm]=runs[nm].sort.reverse[0..4]
          dt<<["<a href=\"/scenario/#{nm}\">#{nm}</a> : ",sc.title,runs[nm].map{|r| " <a href=\"/run/#{r}\">#{r}</a>"}.join(" "),"#{failure_rate(sc.name)}%"]
        end
        @content<<Ruport::Data::Table.new(:data=>dt,:column_names=>["name","title","last 5 runs","failure rate"]).to_html
        @content<<"<br/>"
        @content<<scenario_page_link(page_number,total_pages)
      end
      #Displays the details of a scenario
      def scenario scenario_id=""
        @panel_content=""
        if !scenario_id.empty?
          if scenario_id.to_i==0
            @content=scenario_by_name(scenario_id)
          else
            @content=scenario_in_a_run(scenario_id.to_i)
          end
        else
          return scenarios
        end
      end

      def error
        @content="There was an error"
      end

      def settings
        if request.post?
        end
        @panel_content=panel_runs()
        @title="Settings"
        @content_title="Settings"
        @content=""
      end
      private 
      #Returns a valid page number no matter what __page__ is.
      def validated_page_number page,total_pages
        page_number=page.to_i if page
        page_number||=0
        Ramaze::Log.debug("Total number of run pages is #{total_pages}")
        if page_number<0 || page_number>total_pages-1
          Ramaze::Log.warn("Page number out of bounds: #{page_number}. Reseting")
          page_number=0
        end
        return page_number
      end

      #Renders the summary of all runs for a single scenario
      def scenario_by_name scenario_id
        ret=""
        @title="Runs for #{scenario_id}"
        @content_title="Scenario #{scenario_id} runs"
        begin
          table=Rutema::Model::Scenario.report_table(:all,:conditions=>["name = :spec_name",{:spec_name=>scenario_id}],
          :order=>"run_id DESC")
          if table.empty?
            ret="<p>no results for the given name</p>"
          else
            table.replace_column("status"){|r| scenario_status(r)}
            table.replace_column("name") { |r| "<a href=\"/scenario/#{r}\">#{r}</a>"}
            table.replace_column("start_time"){|r| r.stop_time ? r.start_time.strftime(TIME_FORMAT) : nil}
            table.replace_column("stop_time"){|r| r.stop_time ? r.stop_time.strftime(TIME_FORMAT) : nil}
            table.replace_column("run_id"){|r| "<a class=\"smallgreytext\" href=\"/run/#{r.run_id}\">Run #{r.run_id}</a>"}
            table.reorder("status","run_id","title","start_time","stop_time")
            table.column_names=["status","run","title","started at","ended at"]
            ret<<table.to_html
          end
        rescue
          @content_title="Error"
          @title=@content_title
          Ramaze::Log.error("Could not retrieve data for the scenario name '#{scenario_id}'")
          Ramaze::Log.debug("#{$!.message}:\n#{$!.backtrace}")
          ret="<p>could not retrieve data for the given scenario name</p>"
        end
        return ret
      end
      #Renders the information for a specific executed scenario
      #giving a detailed list of the steps, with status and output
      def scenario_in_a_run scenario_id
        @panel_content=panel_runs
        begin
          scenario=Rutema::Model::Scenario.find(scenario_id)
          @content_title="Summary for #{scenario.name} in run #{scenario.run_id}"
          @title=@content_title
          table=Rutema::Model::Step.report_table(:all,
          :conditions=>["scenario_id = :scenario_id",{:scenario_id=>scenario_id}],
          :order=>"number ASC")
          if table.empty?
            ret="<p>no results for the given id</p>"
          else
            table.replace_column("status"){|r| status_icon(r.status)}
            ret=table.to_vhtml
          end
        rescue
          @content_title="Error"
          @title=@content_title
          Ramaze::Log.error("Could not find scenario with the id '#{scenario_id}'")
          #Ramaze::Log.debug("#{$!.message}:\n#{$!.backtrace}")
          ret="<p>Could not find scenario with the given id.</p>"
        end
        return ret
      end

      #Renders the information for a single run providing the context and a list of the scenarios
      def single_run run_id
        ret=""
        begin
          run=Rutema::Model::Run.find(run_id)
        rescue
          return "Could not find #{run_id}"
        end
        if run.context
          ret<<context_table(run.context)
        end
        conditions="run_id = :run_id AND name NOT LIKE '%_teardown' AND name NOT LIKE '%_setup'"
        table=Rutema::Model::Scenario.report_table(:all,
        :conditions=>[conditions,{:run_id=>run_id}],:except=>["run_id"],
        :order=>"name ASC")
        if table.empty?
          ret<<"No scenarios for run #{run_id}"
        else
          table.replace_column("status") {|r| scenario_status(r) }
          table.replace_column("name"){ |r| "<a href=\"/scenario/#{r.id}\">#{r.name}</a>" }
          table.replace_column("start_time"){|r| r.start_time ? r.start_time.strftime(TIME_FORMAT) : nil}
          table.replace_column("stop_time"){|r| r.stop_time ? r.stop_time.strftime(TIME_FORMAT) : nil}
          table.reorder("status","name","title","start_time","stop_time")
          table.column_names=["status","name","title","started at","ended at"]
          ret<<table.to_html
        end
        return ret
      end

      def panel_runs
        ret=""
        Rutema::Model::Run.find(:all,:limit=>10,:order=>"id DESC").each do |r|
          ret<<"#{status_icon(r.status)} #{run_link(r)}<br/>"
        end
        return ret
      end

      def failure_rate scenario_name
        scenarios=Rutema::Model::Scenario.find(:all,:conditions=>["name = :spec_name",{:spec_name=>scenario_name}])
        failures=0
        scenarios.each{|sc| failures+=1 unless sc.status=="success" }
        return ((failures.to_f/scenarios.size)*100).round
      end
    end

    class StatisticsController < Ramaze::Controller
      include ViewUtilities
      include Settings
      def self.gruff_working= v
        @@gruff_working= v
      end
      def self.gruff_working?
        return @@gruff_working
      end
      begin
        gem 'gruff',"=0.3.4"
        require 'gruff'
        self.gruff_working=true
      rescue LoadError
        self.gruff_working=false
      end
      map '/statistics'
      engine :Erubis
      layout :layout
      #deny_layout :graph
      view_root(File.expand_path(File.join(File.dirname(__FILE__),"view")))
      def index
        @title="Rutema"
        @panel_content=panel_configurations
        @content_title="Statistics"
        @content="<p>rutema statistics provide reports that present the results on a time axis<br/>At present you can see the ratio of successful vs. failed test cases over time grouped per configuration file.</p>"
        @content<<"statistics reports require the gruff gem which in turn depends on RMagick. gruff does not appear to be available!<br/>rutemaweb will not be able to produce statistics reports" unless StatisticsController.gruff_working?
        @content
      end
      def config_report configuration=nil
        @title=configuration || "All configurations" 
        @panel_content=panel_configurations
        @content_title= configuration || "All configurations"
        if StatisticsController.gruff_working?
          @content="<img src=\"/statistics/graph/#{configuration}\"/>"
        else
          @content="Could not generate graph.<p>This is probably due to a missing gruff/RMagick installation.</p><p>You will need to restart rutemaweb once the issue is resolved.</p>"
        end
        return @content
      end
      def graph configuration=nil
        response.header['Content-type'] = "image/png"
        successful=[]
        failed=[]
        labels=Hash.new
        runs=Rutema::Model::Run.find(:all)
        #find all runs beloging to this configuration
        runs=runs.select{|r| r.context[:config_file]==configuration if r.context.is_a?(Hash)} if configuration
        #now extract the data
        counter=0
        #the normalizer thins out the labels on the x axis so that they won't overlap
        normalizer = 1
        normalizer=runs.size/11 unless runs.size<=11
        runs.each do |r|
          fails=r.number_of_failed
          #the scenarios array includes setup and teardown scripts as well - we want only the actual testcases
          #so we use the added number_of_tests method that filters setup and test scripts
          successful<<r.number_of_tests-fails
          failed<<fails
          #every Nth label
          labels[counter]="R#{r.id}" if counter%normalizer==0
          counter+=1
        end
        respond runs_graph_jpg(successful,failed,labels)
      end

      private
      #returns a jpg blob
      def runs_graph_jpg successful,failed,labels
        graph=Gruff::StackedBar.new(640)
        graph.theme = {
          :colors => %w(green red yellow blue),
          :marker_color => 'black',
          :background_colors => %w(white grey)
        }
        graph.x_axis_label="#{successful.size} runs"
        graph.data("successful",successful)
        graph.data("failed",failed)
        graph.labels=labels 
        graph.marker_font_size=12
        return graph.to_blob("PNG")
      end
      #extract all the configuration names
      def configurations
        runs=Rutema::Model::Run.find(:all)
        return runs.map{|r| r.context[:config_file] if r.context.is_a?(Hash)}.compact.uniq
      end
      def panel_configurations
        ret="<a href=\"/statistics/config_report\">all</a><br/>"
        configurations.each do |cfg|
          ret<<cfg_link(cfg)
          ret<<"<br/>"
        end
        return ret
      end
    end
  end
end
