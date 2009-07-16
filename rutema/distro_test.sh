#!/bin/sh
ruby -rubygems -I lib/ bin/rutemax -c test/distro_test/config/minimal.rutema
ruby -rubygems -I lib/ bin/rutemax -c test/distro_test/config/database.rutema
ruby -rubygems -I lib/ bin/rutemax -c test/distro_test/config/full.rutema --check
ruby -rubygems -I lib/ bin/rutemax -c test/distro_test/config/full.rutema 
#rutemax -c test/distro_test/config/minimal.rutema --step