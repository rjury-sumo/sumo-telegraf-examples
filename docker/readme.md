# docker telegraf
Docker images based on https://github.com/influxdata/influxdata-docker
The origional exposes ports which would restrict to one running container per host potentially without jiggery pokery.
In this project we will also include example telegraf.conf files with env vars to make configuration launch more dynamic.

## build
```
docker build -t sumo_telegraf_agent .
```
## setup and run
make sure when you execute the container you have a valid conf file.
you can use one of the templates in ./conf as these are copied to image or supply your own.

```
docker run -it -e SUMO_URL="$SUMO_URL"  -e env=test sumo_telegraf_agent telegraf --config ping.conf
```

## global tags
Posts to sumo with:
_sourcecategory=metrics/telegraf
_sourcehost=hostname
ip=container ip

## env vars
runtime container variables allow you to run potentially multiple container instaces with custom config.
Default values for env vars are defined in entrypoint.sh

### Env vars mandatory for all configs
- SUMO_URL 

### env vars optional for all configs:
- X_SUMO_FIELDS
- env
- service
- location

## ping
Containerised synthetic ping check as per: https://github.com/influxdata/telegraf/tree/master/plugins/inputs/ping
component=ping

# env vars
- urls - hosts to send ping packets to



