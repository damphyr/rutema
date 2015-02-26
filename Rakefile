#  Copyright (c) 2007-2015 Vassilis Rizopoulos. All rights reserved.
# -*- ruby -*-
$:.unshift File.join(File.dirname(__FILE__),"lib")
require 'hoe'
require 'rutema/version'

Hoe.spec "gaudi" do |prj|
  developer("Vassilis Rizopoulos", "vassilisrizopoulos@gmail.com")
  license "MIT"
  prj.version = Rutema::Version::STRING
  prj.summary='rutema is a test execution and management framework for heterogeneous testing environments'
  prj.urls=["http://github.com/damphyr/rutema"]
  prj.description=prj.paragraphs_of('README.md',1..5).join("\n\n")
  prj.local_rdoc_dir='doc/rdoc'
  prj.readme_file="README.md"
  prj.extra_deps<<["patir", "~>0.8.0"]
  prj.extra_deps<<["highline","~>1.6.15"]
  prj.extra_deps<<["mailfactory","~>1.4.0"]
  prj.spec_extras={:executables=>["rutema"],:default_executable=>"rutema"}
end

task :default =>[:test]

task :test do
  require 'coveralls'
  Coveralls.wear!
  require 'minitest/autorun'
  Rake::FileList["#{File.dirname(__FILE__)}/test/test_*.rb"].each do |test_file|
    require_relative "test/#{test_file.pathmap('%n')}"
  end
end

# vim: syntax=Ruby

