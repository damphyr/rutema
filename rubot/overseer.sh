#!/bin/sh
rm -rf test/overseer/example/overseer.db
rm -rf test/overseer/example/rubot_overseer.log
ruby -Ilib/ bin/rubot overseer -b test/overseer/example  --no-log