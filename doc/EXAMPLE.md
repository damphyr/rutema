# A hypothetical example

Let's say we develop a new embedded device powered by a small ARM processor. The device has some communication capabilities and performs a simple task. Any IoT sensor, smart thermostat or garage door control would fit in this category.

During development a variety of tools come in to play. Let's assume in this case that development makes use of a JTAG flasher to install the program on the processor, there is a serial conncetion for control sequences and log output and some kind of script capabilities to stimulate the device's functions and read it's state. 

We want to test that the system starts correctly. In human readable form:

"Flash the device firmware. Reboot the device. Verify that after 5 seconds that the 'Run' state has been reached and the ErrorList is empty."

Breaking down the test steps:

 * Flash the firmware: Find the latest build and flash the firmware using the flash utility
 * Reboot the device: Press the button or use the remote boot utility
 * Wait 5 seconds
 * Load the DebugTool and verify that the state=="Run" and ErrorList is empty

 In XML this could look like
 ```xml
<specification id="T001">
  <title>Startup</title>
  <description>The device starts without problems.</description>
  <scenario>
    <command cmd="flash.exe -P COM4 -f softwareimage.bin --address 0x8000FFFF"/>
    <command cmd="reset.exe -p COM3"/>
    <wait timeout="5"/>
    <command cmd="DebugTool.exe -f startup.script"/>
  </scenario>
</specification>
```
The scenario above works, but is not flexible enough: commands need to be in the path (flash, reset, DebugTool) or fully specified and all those <command cmd=""/> lines are a bit counterintuitive.
How about:

 ```xml
<specification id="T001">
  <title>Startup</title>
  <description>The device starts without problems.</description>
  <scenario>
    <flash image="softwareimage.bin"/>
    <reset/>
    <wait timeout="5"/>
    <debugtool script="startup.script"/>
  </scenario>
</specification>
```

This is a small DSL, specific to the project and in line with the way team members will communicate the steps of the test.
Yet we still need to define all those parameters, the ports and the paths and address spaces. 

This happens in the configuration file, e.g.

```ruby
configure do |cfg|
  cfg.tool={"name"=>"flash",exe=>"c:\\tools\flash\\flasher.exe",address"=>"0x8000FFFF","port"=>"COM4"}
end
```
