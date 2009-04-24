#  Copyright (c) 2008 Vassilis Rizopoulos. All rights reserved.
$:.unshift File.join(File.dirname(__FILE__),"..","..")
require 'rubot/overseer/main'
require 'rubot/gems'
module Rubot
  module Overseer
    #Sets the values we need for public and view directories
    def self.ramaze_settings
       Ramaze::Global.public_root =File.expand_path(File.join(File.dirname(__FILE__),"public"))
       Ramaze::Global.view_root = File.expand_path(File.join(File.dirname(__FILE__),"view"))
    end

    #Helper methods that create HTML snippets
    module ViewUtilities
      #image filename to use for succesfull steps
      IMG_REQ_OK="/images/request_ok.png"
      #image filename to use for failed steps
      IMG_REQ_ERROR="/images/request_error.png"
      #image filename to use for unexecuted steps
      IMG_REQ_WORK="/images/request_working.png"
      #Time format to use for the start and stop times
      TIME_FORMAT="%d/%m/%Y, %H:%M:%S"
      
      DURATION_FORMAT="%H:%M:%S"
      SCRIPT =<<-EOT
        <script type="text/javascript" language="JavaScript">
var timerID = 0;
function is_build_running() {   
   if(timerID) {
      clearTimeout(timerID);
   }
  
  if (typeof XMLHttpRequest != "undefined") {
    req = new XMLHttpRequest();
  } else if (window.ActiveXObject) {
    req = new ActiveXObject("Microsoft.XMLHTTP");
  }
  req.open("GET", "/worker_status_code/internal", true);
  req.onreadystatechange = callback;
  req.send(null);
  timerID  = setTimeout("is_build_running()", 1000);
}

function callback() {
  if (req.readyState == 4) {
    if (req.status == 200) {
      if (req.responseText == "0") {
        window.location.href = "/status/internal";
      }
      else {
        document.getElementById('buildisrunning').style.display="block";
      }
    } else {
      document.getElementById('buildisrunning').innerHTML="error";
    }
  }
}

timerID  = setTimeout("is_build_running()", 1000);
</script> 
      EOT
      # returns the image tag appropriate for the given status
      def status_icon status
        return case status
        when :warning ,"not_executed",:processing,"processing"
          "<img src=\"#{IMG_REQ_WORK}\" align=\"center\"/>"
        when :success, "success","finished",:finished
           "<img src=\"#{IMG_REQ_OK}\" align=\"center\"/>"
        when :error, "error"
           "<img src=\"#{IMG_REQ_ERROR}\" align=\"center\"/>"
        else
           "<img src=\"#{IMG_REQ_WORK}\" align=\"center\"/>"
        end
      end
      
      def request_link r
        "<a href=\"/requests/request/#{r.id}\">#{r.id}</a>"
      end
      # Returns a string with the correct time format for display
      def time_formatted time
        time.strftime(TIME_FORMAT)
      end
      
      def duration_formatted time
        time
      end
    end
    
    class MainController < Ramaze::Controller
      include ViewUtilities
      map '/'
      engine :Erubis
      layout :layout
      deny_layout :worker_status_code
      
      def index
        panel()
        @title="Rubot Overseer"
        
        @content_title="Projects using this Overseer"
        @content="<ul>"
        @@coordinator.configuration.projects.each do |c|
          @content<<"<li><a href=\"#{c[:url]}\">#{c[:name]}</a></li>"
        end
        @content<<"</ul>"
        @content<<"Choose a worker to request a build"
      end
      
      def status worker_name=nil
        if worker_name
          panel()
          worker_status(worker_name)
        else
          return index
        end
        return @content
      end

      def request_build
        panel()
        @title="Build Request"
        if request.post?
          if request.params["sequence"] && request.params["worker"]
            if @@coordinator.build(request.params["worker"],request.params["sequence"])
              @script = SCRIPT
              @content="Requested build of <strong>#{request.params["sequence"]}</strong> on <strong>#{request.params["worker"]}</strong><br><div id=\"buildisrunning\" style=\"display:none;\"><img src=\"/images/animated_progress.gif\"/></div>"
            else
              @content="Problem"
            end
          else
            @content="Malformed build request"
          end
        else
          status
        end
      end

      def cfg
        panel()
        @title="Rubot Overseer Configuration"
        @content_title="Configuration"
        c=@@coordinator.configuration
        @content="The current configuration is:<br/><p>"
        @content<<File.readlines(File.join(c.base,Rubot::Overseer::CFG)).select{|line| line=~/^[\w|\s]/}.join("<br/>")
        @content<<"</p>"
      end

      def log
        panel()
        @title="Rubot Overseer Log"
        @content_title="Log"
        c=@@coordinator.configuration
        if c.logging_to_file
          @content="<pre>"
          @content<<File.read(File.join(c.base,Rubot::Overseer::LOG))
          @content<<"</pre>"
        else
          @content="No log is kept for this instance"
        end
      end

      def error
        @title="Rubot Overseer Error"
        @content_title="Error"
        @content = "There was an unfortunate error (or you tried to be naughty)"
      end
      
      def worker_status_code worker_name
        worker_state=@@coordinator.status_handler.worker_stati[worker_name]
        return -1 unless worker_state
        return 0 if worker_state.free?
        return 1
      end
      
      private
      #returns the status of a worker
      def worker_status worker_name
        worker_state=@@coordinator.status_handler.worker_stati[worker_name]
        if worker_state 
          @title="#{worker_name} status"
          @content_title="Status of #{worker_name}"
          @content="Worker #{worker_state.name} is #{worker_state.status}.<br/>"
          if worker_state.current_build
            build_state=worker_state.current_build
            @content<<"<p>Sequence <a href=\"/requests/request/#{build_state.sequence_id}\">'#{build_state.name}'</a> started on #{time_formatted(build_state.start_time)}"
            @content<<" and ended on #{time_formatted(build_state.stop_time)}</p>" if build_state.stop_time
            @content<<"<p>#{status_icon(build_state.status)}</p>"
          end
          if worker_state.free? && worker_state.online?
            @content<<"Worker is available:<br/>"
            build_form=<<-EOT
            <p>
            <form action="/request_build" method="post" accept-charset="utf-8">
            <select name="sequence">
              <% @@coordinator.sequence_definitions.each do |k,v| %>
                <option value="<%= k %>"><%= k %></option>
              <% end %>
            </select>
            <input type="hidden" name="worker" value="#{worker_name}">
            <input type="submit" value="Build">
            </form>
            </p>
            EOT
            @content<<build_form
          end#if free
        else
          @content="Invalid worker name"
        end#if worker_state
      end
      
      def status_get worker_name
        if worker_name
          worker_status(worker_name)
        else
          @title="Rubot Overseer Status"
          @content_title="Known Workers"
          t=Ruport::Data::Table.new(:column_names=>["Status","Name","Address",""])
          @@coordinator.workers.each do |name,w|
            if @@coordinator.status_handler.worker_stati[name].online?
              status="<img src=\"/images/step_ok.png\"/>"
            else
              status="<img src=\"/images/step_warn.png\"/>"
            end
            t<<[status,"<a href=\"/status/#{name}\">#{name}</a>","<a href=\"#{w.url}\">#{w.url}</a>","<a href=\"/build/#{name}\">build</a>"]
          end
          @content=t.to_html
        end
        return @content
      end
      #forms the left hand panel content:
      #a list of the workers with their stati graphically displayed
      def panel
        @panel_content=""
        t=Ruport::Data::Table.new(:column_names=>["Status","Name"])
        @@coordinator.workers.each do |name,w|
          if @@coordinator.status_handler.worker_stati[name].online?
            status="<img src=\"/images/step_ok.png\"/>"
          else
            status="<img src=\"/images/step_warn.png\"/>"
          end
          t<<[status,"<a href=\"/status/#{name}\">#{name}</a>"]
        end
        @panel_content<<t.to_html
      end
    end
  
    class BuildStatusController <Ramaze::Controller
      include ViewUtilities
      map '/requests'
      engine :Erubis
      layout :layout
      
      view_root(File.expand_path(File.join(File.dirname(__FILE__),"view")))
      def index
        @panel_content=panel()
        @content="The panel on the left presents the last ten requests and their status.<br/>Clicking on a request will give you a detailed status report. You also have access to <a href=\"/builds/all\">all requests</a>."
        @content<<"<p>Status icons and their meanings:<br/><ul><li>#{status_icon("success")} - Build was successful</li><li>#{status_icon("error")} - There was an error</li><li>#{status_icon("processing")} - Working on it</li><ul></p>"
      end
      
      def all
        @content="all"
      end
      
      def error
        @title="Rubot Overseer Error"
        @panel_content=panel()
        @content_title="Error"
        @content = "There was an unfortunate error (or you tried to be naughty)"
      end

      def request request_id=nil
        @panel_content=panel()
        if request_id
          if request_id.to_i !=0
            begin
              req=Rubot::Model::Request.find(request_id)
              @content="Request #{request_id} initiated at #{time_formatted(req.request_time)}"
              @content<<"<p>Build requested: #{req.run.name}</p>"
              
              table=Rubot::Model::Step.report_table(:all,
              :conditions=>["run_id = :run_id",{:run_id=>req.run.id}],
              :order=>"number ASC")
              if table.empty?
                @content="with no steps whatsoever"
              else
                
                table.replace_column("status"){|r| status_icon(r.status)}
                table.replace_column("duration"){|r| duration_formatted(r.duration)}
                @content<<table.to_vhtml
              end
            rescue ActiveRecord::RecordNotFound
              Ramaze::Log.error($!)
              Ramaze::Log.debug($!.backtrace.join("\n"))
              @content="No request with the id '#{request_id}'"
            end
          else
            @content="Unknown request id"
          end
        else
          all()
        end
        return @content
      end
      
      private
      #forms the left hand panel content:
      #a list of the 10 most recent build requests
      def panel
        panel_content=""
        Rubot::Model::Request.find(:all,:order=>"id DESC",:limit=>10).each do |r|
          panel_content<<"#{status_icon(r.status)} #{request_link(r)}<br/>"
        end
        return panel_content
      end
      
    end
    # Formats the test scenario data into a vertical folding structure
    class VerticalTableFormatter < Ruport::Formatter::HTML 

      renders :vhtml, :for => Ruport::Controller::Table

      def build_table_body
        data.each do |row|
          build_row(row)
        end
      end

      def build_table_header
      end

      def build_table_footer
      end

      def build_row(data = self.data)
        output << "<table class=\"vtable\"><colgroup><col width=\"100\"><col></colgroup>\n"
        output << "<tr><td>#{data['status']}</td><td colspan=\"2\"><h3>#{data['number']} - #{data['name']}</h3></td></tr>"
        output << "<tr><td>duration:</td><td>#{data['duration']}</td></tr>\n"
        %w(output error).each { |k| output << "<tr><td colspan=\"2\"><div onclick=\"toggleContentFolding(this)\">#{k} - click me<pre style=\"display:none;\">#{data.get(k)}</pre></div></td></tr>\n" if data.get(k).size > 0 }
        output << "</table>\n"
      end
    end
  end
end