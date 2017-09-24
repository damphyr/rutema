#  Copyright (c) 2007-2017 Vassilis Rizopoulos. All rights reserved.
# -*- ruby -*-
$:.unshift File.join(File.dirname(__FILE__),"lib")
require 'hoe'
require 'rutema/version'

Hoe.spec "rutema" do |prj|
  developer("Vassilis Rizopoulos", "vassilisrizopoulos@gmail.com")
  license "MIT"
  prj.version = Rutema::Version::STRING
  prj.summary='rutema is a test execution and management framework for heterogeneous testing environments'
  prj.urls=["http://github.com/damphyr/rutema"]
  prj.description <<-EOT rutema is a test execution tool and a framework for organizing and managing test execution across different tools.
  
It enables the combination of different test tools while it takes care of logging, reporting, archiving of results and formalizes execution of automated and manual tests.
  
It's purpose is to make testing in heterogeneous environments easier. 
EOT
  prj.local_rdoc_dir='doc/rdoc'
  prj.readme_file="README.md"
  prj.extra_deps<<["patir", "~>0.8"]
  prj.extra_deps<<["highline","~>1.7"]
  prj.spec_extras={:executables=>["rutema"],:default_executable=>"rutema"}
end

Rake::Task[:default].clear()

task :default =>[:"test:coverage"]

task :"test:coverage" do
  require "test-unit"
  require 'coveralls'
  Coveralls.wear!
  Rake::FileList["#{File.dirname(__FILE__)}/test/test_*.rb"].each do |test_file|
    require_relative "test/#{test_file.pathmap('%n')}"
  end
end

# vim: syntax=Ruby

