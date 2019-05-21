#!/bin/sh

set -e

build=no
if [ "$1" = 'and' ] && [ "$2" = 'build' ]; then
  shift; shift
  build=yes
fi

set -e

do_build() {
  printf "building...\r"
  shards build > /dev/null
  printf "building...done\nAll OK\n"
}

crystal tool format
ameba
KEMAL_ENV=test crystal spec $@
[ $build = yes ] && do_build
