#!/bin/bash
set -e

if [ "${1:0:1}" = '-' ]; then
    set -- telegraf "$@"
fi

# env validation
if [ -n "$SUMO_URL" ]; then
  echo "collection endpoint: $SUMO_URL" 
else
  echo "ERROR you must provide a SUMO_URL env var to run this telegraf container."
  exit 1
fi

# global defaults
export X_SUMO_FIELDS=${X_SUMO_FIELDS:='ignore=me'}
export env=${env:='none'}
export service=${service:='none'}
export location=${location:='none'}
export ip=`hostname -i`

# ping defaults
export urls=${urls:='sumologic.com'}

exec "$@"
