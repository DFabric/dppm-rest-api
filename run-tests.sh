#!/bin/sh

set -ue

crystal tool format
ameba
KEMAL_ENV=test crystal spec
printf "building...\r"
shards build > /dev/null
printf "building...done\nAll OK\n"
