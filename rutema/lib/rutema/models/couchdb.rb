#  Copyright (c) 2007 Vassilis Rizopoulos. All rights reserved.
$:.unshift File.join(File.dirname(__FILE__),'..','..')
require 'rutema/models/base'
require 'couchrest'
module Rutema
  module CouchDB
    def self.connect cfg,logger
      if cfg[:url] && cfg[:database]
        if cfg[:user] && cfg[:password]
        end
        return CouchRest.database!("#{cfg[:url]}/#{cfg[:database]}")
        
      else
        raise Rutema::ConnectionError,"Erroneous database configuration. Missing :url and/or :database"
      end
    end
    class Run <CouchRest::ExtendedDocument
      unique_id :slug
      
      timestamps!
      
      view_by :slug, :descending=>true
      
      property :slug, :read_only => true
      property :context
      property :scenarios
      property :parse_errors
      
      set_callback :save, :before, :generate_slug_from_payload
      def generate_slug_from_payload
        self['slug']=Digest::SHA1.hexdigest("#{self['context']},#{self['scenarios']}")
      end
    end
  end
end