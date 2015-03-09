# Configuration

rutema's configuration files serve as a means to decouple the DSL from the specific parameters. In this way we can change the adapt the behaviour of the tools without having to update the specifications.

The configuration files are legal Ruby, but don't let that scare you. While following the standard "rutema Way" you won't have to learn a new programming language, just a bit of wigly syntax.

The example below documents all options available:

```ruby
configure do |cfg|
  #the parser to use - yes, this is the class name as used in the code
  cfg.parser={:class=>Rutema::Parsers::XML}
  #the default reporter definitions. They can be overwritten
  #only one reporter of each class can be defined, last definition wins
  #cfg.reporter={:class=>Rutema::Reporters::Console, "silent"=>false}
  #cfg.reporter={:class=>Rutema::Reporters::Summary, "silent"=>false}
  #define a tool to be used. This is info that the parser will use to create commands.
  cfg.tool={:name=>"echo",:path=>"echo.exe",:configuration=>{:info=>"important"}}
  #A path. Another way to pass information to the parser or the reporters. 
  cfg.path={:name=>"SourcePath",:path=>"../../lib"}
  #The setup specification filename. This runs before every test when defined
  cfg.setup="setup.spec"
  #The teardown specification filename. This runs after every test when defined
  cfg.teardown="teardown.spec"
  #The check specification filename. If you define this, then it will run first of all and if it fails
  #no more tests are run. This is a good way to check your test rig's integrity
  cfg.check="check.spec"
  #An array (the [] thingies) of specification filenames
  cfg.tests=["test.spec","more_tests/test2.spec"]
  #A hash of data for passing information to the system. Use it to pass data to your reporters
  cfg.context={:tester=>"damphyr",:version=>"0.2.345"}
end
```

There is a major flaw in the above configuration file and it becomes immediately obvious once you have a few dozen test specifications. You can't possibly expect us to force you to add every single test specification filename by hand?!
            
Well...ofcourse not. Here is where using Ruby as a configuration language shines:
```ruby
require 'rake'
configure do |cfg|
  cfg.tests=Rake::FileList["a_lot_of_tests_dir/*.spec"]
end
```
The above will add all *.spec* files to the tests used, making use of the Rake library's code for scanning the filesystem.

The configuration file in this example serves as a single source for all the parameters for all the tools and also defines the suite of tests to run. This is not very practical. In order to be able to compose configuration files we use the import statement:

```ruby
configure do |cfg|
  cfg.import("tools.rutema")
end
```

Relative paths are always relative to the location of the configuration file.