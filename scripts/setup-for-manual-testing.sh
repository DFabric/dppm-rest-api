#!/bin/sh

set -eux

ADMIN=no # By default don't create an admin user
for arg in $@; do
  if [ "$arg" = "with-admin" ]; then
    ADMIN=yes
  fi
done

make_admin() {
  bin/dppm server group add "name=admin's group" id=0 permissions='
      {
        "/**": {
          "permissions": [
            "Create", "Read", "Update", "Delete"
          ],
          "query_parameters": { }
        }
      }'
  bin/dppm server user add name=admin groups=0
}

DATA_DIR="${DATA_DIR:-"$PWD/data"}"
DPPM_EXE="${DPPM_EXE:-"$PWD/bin/dppm"}"
DPPM_USER="${DPPM_USER:-user}"
GROUP_ID="${GROUP_ID:-1000}"

mkdir $DATA_DIR ||: nbd
echo '{"groups":[], "users": []}' > $DATA_DIR/permissions.json

shards.old build
bin/dppm server group add "name=${DPPM_USER}s group" id=$GROUP_ID
bin/dppm server user add "name=$DPPM_USER" groups=$GROUP_ID

if [ $ADMIN = yes ]; then
  make_admin
fi

bin/dppm server run webui_folder="$(dirname $PWD)/svelte/public"

rm -r data
