## rutema examples
The examples included herein are also used to test the rutema functionality, so you know they work.

## Structure
The basic structure we follow in rutema usage (and this has been "in production" for a good 5 years now) is a config/ directory where each suite is configured, a specs/ directory to store the test specifications and a scritps/ directory for any scripts and data files used by the steps in the scripts directory. 

We also usually add any custom code used in the configuration files in config/lib so that it can be required in the configuration files without much trouble.