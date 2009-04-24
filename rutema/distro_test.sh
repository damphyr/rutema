#!/bin/sh
rutemax -c test/distro_test/config/minimal.rutema
rutemax -c test/distro_test/config/database.rutema
rutemax -c test/distro_test/config/full.rutema --check
rutemax -c test/distro_test/config/full.rutema 
#rutemax -c test/distro_test/config/minimal.rutema --step