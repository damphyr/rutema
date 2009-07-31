#  Copyright (c) 2008 Vassilis Rizopoulos. All rights reserved.
$:.unshift File.join(File.dirname(__FILE__),"..")
require 'sinatra/base'
require 'erb'
require 'patir/configuration'
require 'patir/command'
require 'patir/base'
require 'rutema_web/model'
require 'rutema_web/ruport_formatter'

module RutemaWeb
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
        #Ramaze::Log.debug("Summary snippet for #{r}") if @logger
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
      DEFAULT_PAGE_SIZE=10
      @@rutemaweb_settings||=Hash.new
      #Set to true to show all setup and teardown scenarios
      def show_setup_teardown= v
        @@rutemaweb_settings[:show_setup_teardown]= v
      end 

      def show_setup_teardown?
        return @@rutemaweb_settings[:show_setup_teardown]
      end

      def page_size= v
        @@rutemaweb_settings[:page_size]=v
      end

      def page_size
        @@rutemaweb_settings[:page_size]||=DEFAULT_PAGE_SIZE
        return @@rutemaweb_settings[:page_size]
      end
    end
  
    module Statistics
      def self.gruff_working= v
        @@gruff_working= v
      end
      def self.gruff_working?
        return @@gruff_working
      end
      begin
        require 'gruff'
        self.gruff_working=true
      rescue LoadError
        self.gruff_working=false
      end
     
      private
      #returns a jpg blob
      def runs_graph_jpg successful,failed,not_executed,labels
        graph=Gruff::StackedBar.new(640)
        graph.theme = {
          :colors => %w(green red yellow blue),
          :marker_color => 'black',
          :background_colors => %w(white grey)
        }
        graph.x_axis_label="#{successful.size} runs"
        graph.data("successful",successful)
        graph.data("failed",failed)
        graph.data("not executed",not_executed)
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
    
    module Timeline
      #Collects the timeline information from a set of runs.
      #Essentially this lists the status for all scenarios in each run
      #filling in not_executed status for any missing entries
      def timeline_data runs
#        {:scenario=>{"run_id"=>status}}
        data=Hash.new
        runs.each do |run|
          run.scenarios.each do |scenario|
            unless scenario.name=~/_setup$/ || scenario.name=~/_teardown$/
              data[scenario.name]||={}
              data[scenario.name][run.id]=[scenario.status,scenario.id]
            end
          end
        end
        #fill in the blanks
        data.each do |k,v|
          runs.each do |run|
            data[k][run.id]=["not_executed",nil] unless data[k][run.id]
          end
        end
        return data
      end
    end
   
    class SinatraApp<Sinatra::Base
      include ViewUtilities
      include Settings
      include Statistics
      include Timeline
      attr_accessor :title,:panel_content,:content_title,:content
      enable :logging
      enable :run
      enable :static
      set :server, %w[thin mongrel webrick]
      set :port, 7000
      set :root, File.dirname(__FILE__)
      set :public, File.dirname(__FILE__) + '/public'
      
      @@logger = Patir.setup_logger
      
      get '/' do
        page_setup "Rutema",panel_runs,"Welcome to Rutema","<p>This is the rutema web interface.<br/>It allows you to browse the contents of the test results database.</p><p>Currently you can view the results for each separate run, the results for a specific scenario (a complete list of all steps executed in the scenario with standard and error output logs) or the complete execution history of a scenario.</p><p>The panel on the left shows a list of the ten most recent runs.</p>"
        erb :layout 
      end
      #Displays the details of a run
      #
      #Routes to /runs if no id is provided
      get '/run/:run_id' do |run_id|
        page_setup "Run #{run_id}",panel_runs,"Summary of run #{run_id}",single_run(run_id)
        erb :layout
      end
      
      get '/run/?' do
        runs(0)
        erb :layout
      end
      
      get '/runs/?' do
        runs(0)
        erb :layout
      end
      
      get '/runs/:page' do |page|
        runs(page)
        erb :layout
      end
      #Displays a paginated list of scenarios
      get '/scenarios/:page' do |page|
        scenarios(page)
        erb :layout
      end
      #Displays the details of a scenario
      get '/scenario/:scenario_id' do |scenario_id|
        if scenario_id.to_i==0
          @content=scenario_by_name(scenario_id)
        else
          @content=scenario_in_a_run(scenario_id.to_i)
        end
        erb :layout
      end
      
      get '/scenario/?' do
        scenarios(0)
        erb :layout
      end
    
      get '/scenarios/?' do
        scenarios(0)
        erb :layout
      end
      
      get '/statistics/?' do
        page_setup "Rutema",panel_configurations,"Statistics"
        @content="<p>rutema statistics provide reports that present the results on a time axis<br/>At present you can see the ratio of successful vs. failed test cases over time grouped per configuration file.</p>"
        @content<<"statistics reports require the gruff gem which in turn depends on RMagick. gruff does not appear to be available!<br/>rutemaweb will not be able to produce statistics reports" unless Statistics.gruff_working?
        erb :layout
      end

      get '/statistics/config_report/:configuration' do |configuration|
        tt=configuration || "All configurations"
        page_setup(tt,panel_configurations,tt)
        
        if Statistics.gruff_working?
          @content="<img src=\"/statistics/graph/#{configuration}\"/>"
        else
          @content="Could not generate graph.<p>This is probably due to a missing gruff/RMagick installation.</p><p>You will need to restart rutemaweb once the issue is resolved.</p>"
        end
        erb :layout
      end

      get '/statistics/graph/:configuration' do |configuration|
        content_type "image/png"
        successful=[]
        failed=[]
        not_executed=[]
        labels=Hash.new
        runs=all_runs_in_configuration(configuration)
        #now extract the data
        counter=0
        #the normalizer thins out the labels on the x axis so that they won't overlap
        normalizer = calculate_normalizer(runs.size)
        runs.each do |r|
          fails=r.number_of_failed
          no_exec = r.number_of_not_executed
          #the scenarios array includes setup and teardown scripts as well - we want only the actual testcases
          #so we use the added number_of_tests method that filters setup and test scripts
          successful<<r.number_of_tests-fails-no_exec
          failed<<fails
          not_executed<<no_exec
          #every Nth label
          labels[counter]="R#{r.id}" if counter%normalizer==0
          counter+=1
        end
        runs_graph_jpg(successful,failed,not_executed,labels)
      end
      
      get '/statistics/timeline/:configuration' do |configuration|
        page_setup "Rutema",nil,"Timeline for #{configuration}"
        data=timeline_data(all_runs_in_configuration(configuration))
        @content="<table class=\"timeline\">"
        data.each do |sc_name,run_data|
          @content<<"<tr><td>#{sc_name}</td>"
          run_data.keys.sort.each do |key|
            sc_data=run_data[key]
            @content<<"<td class=\"#{sc_data[0]}\">"
            if sc_data[1]
              @content<<"<a class=\"timeline\" href=\"/scenario/#{sc_data[1]}\">#{key}</a>"
            else
              @content<<"<span class=\"timeline\">#{key}</span>"
            end
            @content<<"</td>"
          end
          @content<<"</tr>"
        end
        @content<<"</table>"
        erb :layout
      end
      private
      #calculates a divider to sparse out the laels in statistics graphs
      def calculate_normalizer siz
        #the normalizer thins out the labels on the x axis so that they won't overlap
        return siz<=11 ? 1 : siz/11
      end
      #finds all the runs belonging to a specific configuration
      def all_runs_in_configuration configuration
        runs=Rutema::Model::Run.find(:all)
        #find all runs beloging to this configuration
        runs.select{|r| r.context[:config_file]==configuration if r.context.is_a?(Hash)} if configuration
      end
      #sets the variables used in the layout template
      def page_setup title,panel_content,content_title,content=""
        @title=title
        @panel_content=panel_content
        @content_title=content_title
        @content=content
      end
      
      def runs page
        page_setup "All runs",nil,"All runs"

        dt=[]
        total_pages=(Rutema::Model::Run.count/page_size)+1
        page_number=validated_page_number(page,total_pages)

        runs=Rutema::Model::Run.find_on_page(page_number,page_size)
        runs.each do |r| 
          dt<<[status_icon(r.status),run_summary(r),r.config_file]
        end
        @content<< Ruport::Data::Table.new(:data=>dt,:column_names=>["status","description","configuration"]).to_html
        @content<<"<br/>"
        @content<<run_page_link(page_number,total_pages)
      end
    
      def scenarios page
        page_setup "All scenarios",panel_runs,"All scenarios"
        runs=Hash.new
        #find which runs contain each scenario with the same name
        #Ramaze::Log.debug("Getting the runs for each scenario")
        conditions="name NOT LIKE '%_teardown' AND name NOT LIKE '%_setup'"
        Rutema::Model::Scenario.find(:all, :conditions=>conditions).each do |sc|
          nm=sc.name
          runs[nm]||=[]
          runs[nm]<<sc.run.id
        end
        #the size of the hash is also the number of unique scenario names
        total_pages=(runs.size / page_size)+1
        page_number=validated_page_number(page,total_pages)
        #Ramaze::Log.debug("Getting scenarios for page #{page_number}")
        scens=Rutema::Model::Scenario.find_on_page(page_number,page_size,conditions)
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
      #Returns a valid page number no matter what __page__ is.
      def validated_page_number page,total_pages
        page_number=page.to_i if page
        page_number||=0
        #Ramaze::Log.debug("Total number of run pages is #{total_pages}")
        if page_number<0 || page_number>total_pages-1
          #Ramaze::Log.warn("Page number out of bounds: #{page_number}. Reseting")
          page_number=0
        end
        return page_number
      end

      #Renders the summary of all runs for a single scenario
      def scenario_by_name scenario_id
        ret=""
        page_setup "Runs for #{scenario_id}",nil,"Scenario #{scenario_id} runs"
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
          content_title="Error"
          title=content_title
          #Ramaze::Log.error("Could not retrieve data for the scenario name '#{scenario_id}'")
          #Ramaze::Log.debug("#{$!.message}:\n#{$!.backtrace}")
          ret="<p>could not retrieve data for the given scenario name</p>"
        end
        return ret
      end
      #Renders the information for a specific executed scenario
      #giving a detailed list of the steps, with status and output
      def scenario_in_a_run scenario_id
        begin
          scenario=Rutema::Model::Scenario.find(scenario_id)
          page_setup "Summary for #{scenario.name} in run #{scenario.run_id}",panel_runs,"Summary for #{scenario.name} in run #{scenario.run_id}"
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
          content_title="Error"
          title=content_title
          #Ramaze::Log.error("Could not find scenario with the id '#{scenario_id}'")
          @@logger.warn("#{$!.message}:\n#{$!.backtrace}")
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
    end#SinatraApp
  end#UI module
end