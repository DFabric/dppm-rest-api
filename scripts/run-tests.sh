#!/bin/sh

set -eu

build=no
if [ "${1-}" = "build" ]; then
  shift
  build=yes
fi

do_build() {
  printf "building...\r"
  shards build -q
  printf "building...done\n"
}

crystal tool format
bin/ameba
KEMAL_ENV=test crystal spec $@
[ $build = yes ] && do_build
echo All OK
