# Linux observability demo for Sumo Logic Using Telegraf

# Overview
This is a demo project to show how we can 
- use telegraf to collect and forward base level metrics to sumo for disk, cpu, mem etc
- create a custom explore hierarchy using metric tags
- add custom stack linked dashboards to explore
- create example alerts.

# Design Considerations

## collection
Metrics will be streamed in prometheus format to sumo HTTPS source using the sumologic output plugin. 

## sumo metadata
- _collector and _source will represent the hosted collection endpoints
- sourcecategory: set to 'metrics/telegraf'.  A real world telegraf implmentation could have many sources included in a telegraf.conf file, so by keeping the sourcecategory generic we ensure telegraf sourced metrics are easily identified in sumo.
- sourceHost: telegraf sends a 'host' tag but we will also send _sourcehost correctly for consistency on sumo side.

## Tagging
We need a consistent and generic metric tag scheme to enable reporting in sumo by key dimensions, and to build a custom heirarchy in explore.

Each metric set sent should have a 'component' tag set that will be the primary method to group telegraf metrics sent.

The actual tags used could vary between customer environments but should include things like:
- environment
- application / service name
- datacenter or cloud provider
- technical/business or budget owners

This example has hardcoded tags but best practice would be to set these as environment variables instead.
```
    component="os-linux"
    environment="test"
    datacenter="us-east-2"
    service="myservice"
    user = "${USER}"
```
### input level tags
example using redis input
```
    [inputs.redis.tags]
    environment="prod"
    component="database"
    db_system="redis"
    db_cluster="redis_prod_cluster01"
```

## Hierarchy
We can use the explorer views API to create one or more custom heirarchies for example:
- environment / service / component
- service / environment / component
- component / service / environment
and so on.

Users could additionally use the filters feature in explore to search by any tags applied.

## Stack Linking 
Once you have decided on the key tag dimensions to build your hierarchy you should start with building a comonent level dashboard that includes filters for all hierarchy level tags, plus any others that might be useful.

This can then be 'stack linked' to the component level.

You can then build and stack link higher level views that might show say per service or per environment summaries for all components you are deploying.

So for example the 'component' level might include things like:
- os-linux
- database
- nginx

## DPM
Sumo metrics is a volume based charging model on DPM (Data Pointes Per Minute). This is impacted by several key factors:
1. the interval/flush interval. more frequent data points generate more DPM
2. number of metric series. Use namepass / fieldpass etc to restrict collected metrics to only useful ones.
3. tag cardinality: be careful of tags that introduce higher cardinality as this will result in more DPM if there are many permutations over a short time range.

# Setup

## Collection
Create a hosted collector and HTTPS Source, note the url for later.

## telgraf install
See: https://help.sumologic.com/03Send-Data/Collect-from-Other-Data-Sources/Collect_Metrics_Using_Telegraf/03_Install_Telegraf#install-telegraf-in-a-non-kubernetes-environment

# telegraf configuration
Use the supplied linux.telegraf.conf example as a start point.

## output url
Make sure to set SUMO_URL environment variable to match the https source you created earlier.

## tags
Note that we have a global tag component="os-linux"
Set global and/or input level tags to match the hierarchy levels that you want to use in your organization. 
It's recommended to use environment variables or a code pipeline to parameterize these to avoid hardcoding them in your configuration file.

Such as:
```
    component="os-linux"
    environment="test"
    datacenter="us-east-2"
    service="myservice"
    user = "${USER}"
```

## metadata
The output plugin is setup to send specific sumo metadata.

sourcecategory and component will be key properties for metric scoping later building dashboards, hierarchy and stack links.
_sourcecategory=metrics/telegraf
_sourcehost=<local hostname>