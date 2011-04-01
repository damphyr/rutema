#!/bin/sh
ruby -I lib/ bin/rutema -c test/distro_test/config/minimal.rutema
ruby -I lib/ bin/rutema -c test/distro_test/config/database.rutema
ruby -I lib/ bin/rutema -c test/distro_test/config/full.rutema --check
ruby -I lib/ bin/rutema -c test/distro_test/config/full.rutema 
#rutemax -c test/distro_test/config/minimal.rutema --step