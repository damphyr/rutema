#  Copyright (c) 2008 Vassilis Rizopoulos. All rights reserved.
$:.unshift File.join(File.dirname(__FILE__),"..")
require 'worker/main'
require 'rubot/gems'

module Rubot
  module Worker
    module UI
      class MainController < Ramaze::Controller
        map '/'
        engine :Erubis
        layout :layout
        Ramaze::Route[ '/' ] = '/status'
        
        def status
          @content_title="Status"
          if @@coordinator.runner.free?
            @content="There is currently no active build"
            if @@coordinator.status.build
              @content<<"<br/>The last build's report:<hr>"
              @content<<"<p>#{@@coordinator.status.build.to_s}</p>"
            else
              @content<<", and apparently this worker has not done any work...ever. Tsk, tsk, tsk."
            end
          else
          end
        end
        
        def cfg
          @content_title="Configuration"
          @content="The current configuration is:<br/><p>"
          @content<<File.readlines(@@coordinator.configuration.filename).select{|line| line=~/^\w/}.join("<br/>")
          @content<<"</p>"
        end
        
        def log
          @content_title="Log"
          c=@@coordinator.configuration
          if c.logging_to_file
            @content=File.readlines(File.join(c.base,Rubot::Worker::LOG)).join("<br/>")
          else
            @content="No log is kept for this instance"
          end
        end
        
        def build
          if request.post?
          else
            status
          end
        end
      
        def error
          @content_title="Error"
          @content = "#{Ramaze::Dispatcher::Error.current.message}"
        end
      end
    end
  end
end