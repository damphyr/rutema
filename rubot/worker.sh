#!/bin/sh
rm -rf worker
mkdir worker
cp test/worker/samples/valid_worker_config.cfg worker/rubot_worker.cfg
ruby -Ilib bin/rubot worker -b worker/ -d --no-log
#ruby -Ilib bin/rubot worker -b worker/ -d 