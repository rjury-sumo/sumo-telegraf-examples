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
export interval=${interval:='60s'}
export flush_interval=${flush_interval:='60s'}

# urls can be a list which is tricky to replace
# use just a csv list with no quotes and we will reformat that into a list correctly
if  echo "$urls" | grep ','; then 
  urlslist=`echo $urls | sed 's/,/","/g'`
fi

if  echo "$urls" | grep ',' > /dev/null 2>&1; then 
  sed -i "s|.{urls}|$urlslist|g" ping.conf; 
  sed -i "s|.{urls}|$urlslist|g" http_response.conf; 
  cat http_response.conf | grep "urls ="
fi

exec "$@"
