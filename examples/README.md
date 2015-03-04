## rutema examples

Were would we be without working examples.

## Structure

The basic structure we follow in rutema usage (and this has been "in production" for almost a decade) is

````
config/ 
specs/
scripts/
suites/
````

Configuration files are stored in config/ and suites/ and have per convention the extension .rutema.
Tool, path and test environment specific configuration is saved in config/ and the collection of tests to run per configuration in suites/

##rutema tooling

The configuration system allows us to replace every part of the rutema engine. They are only three major parts anyway: the parser, the runner and the reporter. The parser must be specified, it handles the specific testing language you will develop for the project. 

The runner is the easiest to provide a default implementation for and the reporters that can be made available are limited only by the time you have to come up with solutions but a simple console output is easy to provide. 

The following shows the default configuration if it was explicitly spelled out in a .rutema file:

````
configure do |cfg|
  cfg.parser={:class=>Rutema::Parsers::XML}
  cfg.runner={:class=>Rutema::Runners::Default}
  cfg.reporter={:class=>Rutema::Reporters::Console}
end
```` 

Every parser, runner or reporter will receive the complete rutema configuration as a parameter upon instantiation. This means that whatever you add to the Hash will be accessible within the class' constructor. It comes handy.
