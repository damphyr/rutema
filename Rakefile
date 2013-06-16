#  Copyright (c) 2007-2010 Vassilis Rizopoulos. All rights reserved.
# -*- ruby -*-
$:.unshift File.join(File.dirname(__FILE__),"lib")
require 'hoe'
require 'rutema/version '

Hoe.spec('rutema') do |p|
  p.version=Rutema::Version::STRING
  p.rubyforge_name = 'patir'
  p.author = "Vassilis Rizopoulos"
  p.email = "vassilisrizopoulos@gmail.com"
  p.summary = 'rutema is a test execution and management framework for heterogeneous testing environments'
  p.description = p.paragraphs_of('README.md', 1..4).join("\n\n")
  p.urls= ["http://github.com/damphyr/rutema"]
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
  p.extra_deps<<["patir", "~>0.8.0"]
  p.extra_deps<<["highline","~>1.6.15"]
  p.extra_deps<<["mailfactory","~>1.4.0"]
  p.spec_extras={:executables=>["rutema"]}
end

task :default =>[:test,:system_tests]

task :system_tests do 
  Dir.chdir(File.join(File.dirname(__FILE__),'examples')) do 
    sh('./system_test.sh')
  end
end
# vim: syntax=Ruby

