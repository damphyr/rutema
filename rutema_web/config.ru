#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__),"lib")
require 'rubygems'
require 'bundler/setup'
require 'rutema_web/main'

cfg_file=File.join(Dir.pwd,"examples/rutema_web.yaml")
RutemaWeb.start(cfg_file)
