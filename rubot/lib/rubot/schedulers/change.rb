#  Copyright (c) 2007 Vassilis Rizopoulos. All rights reserved.
$:.unshift File.join(File.dirname(__FILE__),"..","..")
require 'rubot/base.rb'

module Rubot
    module Schedulers
      #A ChangeScheduler receives Change events and decides if it will sent a Rubot::BuildRequest to any Rubot::Worker based on Rubot::Rule instances
      #
      #The decision is based on Rule instances provided during the schedulers' instantiation.
      class ChangeScheduler
        def initialize coordinator,logger=nil
          @logger= logger || Patir.setup_logger
          @coordinator=coordinator
          @logger.info("Starting change scheduler")
          @rules=coordinator.rules
        end
        #processes a Change
        def change change_data
          #only if it is a Change
          if change_data.is_a?(Change)
            @logger.debug(change_data.to_s)
            rule_parameters={:branch=>change_data.branch,:repository=>change_data.repository}
            change_data.changeset.each do |c|
              @rules.each do |r| 
                @logger.debug("Checking rule #{r.to_s}")
                rule_parameters[:filename]=c.filename
                if r.matches?(rule_parameters)
                  worker=r.workers[0]
                  #Find a free worker
                  r.workers.each do |w|
                    if @coordinator.status_handler.worker_stati[w].free?
                      worker=w
                      break
                    end  
                  end
                  #sent it back
                  @coordinator.build(worker,r.sequence,change_data)
                end
              end
            end
            return true
          else
            @logger.error("#{change_data} cannot be handled as a change")
            return false
          end
        end
        private
      end
    end
end