#  Copyright (c) 2007-2017 Vassilis Rizopoulos. All rights reserved.
# -*- ruby -*-
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "lib")
require "hoe"
require "rutema/version"

Hoe.spec "rutema" do |prj|
  developer("Vassilis Rizopoulos", "vassilisrizopoulos@gmail.com")
  license "MIT"
  prj.version = Rutema::Version::STRING
  prj.summary = "rutema is a test execution and management framework for heterogeneous testing environments"
  prj.urls = { "home" => "http://github.com/damphyr/rutema" }
  prj.description = <<~DESC
    rutema is a test execution tool and a framework for organizing and managing test execution across different tools.\nIt enables the combination of different test tools while it takes care of logging, reporting, archiving of results and formalizes execution of automated and manual tests.\nIt's purpose is to make testing in heterogeneous environments easier.
  DESC
  prj.local_rdoc_dir = "doc/rdoc"
  prj.readme_file = "README.md"
  prj.extra_deps << ["patir", "~>0.9"]
  prj.extra_deps << ["highline", "~>2.0"]
  prj.spec_extras = { :executables => ["rutema"] }
end

Rake::Task[:default].clear

task :default => [:"test:coverage"]

desc "Run tests with coverage analysis"
task :"test:coverage" do
  require "test-unit"
  require "coveralls"
  Coveralls.wear!
  Rake::FileList["#{File.dirname(__FILE__)}/test/test_*.rb"].each do |test_file|
    require_relative "test/#{test_file.pathmap('%n')}"
  end
end

# vim: syntax=Ruby
