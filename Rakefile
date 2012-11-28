#  Copyright (c) 2007-2010 Vassilis Rizopoulos. All rights reserved.
# -*- ruby -*-
$:.unshift File.join(File.dirname(__FILE__),"lib")
require 'rutema/system'
require 'rubygems'
require 'hoe'

Hoe.spec('rutema') do |p|
  p.version=Rutema::Version::STRING
  p.rubyforge_name = 'patir'
  p.author = "Vassilis Rizopoulos"
  p.email = "vassilisrizopoulos@gmail.com"
  p.summary = 'rutema is a test execution and management framework for heterogeneous testing environments'
  p.description = p.paragraphs_of('README.md', 1..4).join("\n\n")
  p.url = "http://patir.rubyforge.org/rutema"
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
  p.extra_deps<<["activerecord", "~>3.0.9"]
  p.extra_deps<<["patir", "~>0.7.2"]
  p.extra_deps<<["highline","~>1.6.2"]
  p.extra_deps<<["mailfactory","~>1.4.0"]
  p.extra_deps<<["mocha","~>0.9.12"]
  p.extra_deps<<["sqlite3","~>1.3.4"]
  p.spec_extras={:executables=>["rutemax","rutema"]}
end

# vim: syntax=Ruby
