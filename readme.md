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

### global tags
This example has hardcoded tags but best practice would be to set these as environment variables instead. See the user row as an example:
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
- telegraf by component
and so on.

So for example the 'component' level might include things like:
- os-linux
- database
- nginx
and any other telegraf plugins we want to integrate into sumo and the heirarchy tree.

Note: users could additionally use the filters feature in explore to search by any tags applied see [filter explore](https://help.sumologic.com/Visualizations-and-Alerts/Explore/Filter_Explore).


## DPM and Credits Consumption
Sumo metrics is a volume based charging model on DPM (Data Pointes Per Minute) which might say consume 3 credits per 1000 DPM averaged over 1 day. 

This means more DPM will consume more credits.

This is impacted by several key factors:
1. the interval/flush interval. more frequent data points generate more DPM
Pay close attentin to what settings you are using for 
  interval = "15s"
  flush_interval = "15s"
more frequent metrics will result in higher granulaity but higher DPM consumption per host.

2. number of metric series. Use namepass / fieldpass etc to restrict collected metrics to only useful ones.
3. tag cardinality: be careful of tags that introduce higher cardinality as this will result in more DPM if there are many permutations over a short time range.

so in putting together this template example we have filtered out many of the default base linux metrics & fields to reduce out of the box cardinality per host (and hence the overall number of DPM.)

4. procstat - the template includes an example config to monitor java processes on a host. It's recommneded to monitor only specific processes this way as you will get multiple dpm per process per host, and there can be hundreds of running processes on a single host!

# Setup

## Collection
Create a hosted collector and HTTPS Source, note the url for later.

## telgraf install
See: https://help.sumologic.com/03Send-Data/Collect-from-Other-Data-Sources/Collect_Metrics_Using_Telegraf/03_Install_Telegraf#install-telegraf-in-a-non-kubernetes-environment

# telegraf configuration
Use the supplied [config/linux.telegraf.conf](config/linux.telegraf.conf)] example as a start point. This includes the typical linux host plugins to get us coverage of:
- disk
- cpu
- memory
- swap
- diskio
- system (uptime etc)
- process count
- procstat - provides example of per process montioring.

You can also find some examples for nginx or redis plugins. You can add any other plugins just consider up from what component value you will use and how stack linking might be achieved.

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

## importing demo app


## build a hierarchy 
Once you have decided on a heirarchy and made sure the metrics collected have matching tag dimensions configured we can build one more heirarchies using the explore API. There are various ways to structure a heirarchy you can see examples of different approaches in this file [hr-all.demo.json](./explore/hr-all-demo.json) This is a get of all standard sumo hierarchy types from a demo org.

### Custom hierarchy by component tags
We can build a hierarchy 1 level deep to show content for each telgraf plugin that is integrated.

If you refer to [hr-os-nginx-redis.json](explore/hr-os-nginx-redis.json) you will see we can show each new component as a level, then have a dynamic list of all nodes in the that level with something like this:
```
{
    "name": "telegraf-components",
    "level": {
        "entityType": "component",
        "nextLevelsWithConditions": [
            {
                "condition": "os-linux",
                "level": {
                    "entityType": "_sourcehost",
                    "nextLevelsWithConditions": [],
                    "nextLevel": null
                }
            },
```

Use a API call to upload the new hierarchy similar to the new-hr.py scripts in ./explore.
![component hierarchy](docs/telegraf-components-hr.png "component hierarchy")


### Custom hierarchy by business tags
If you refer to the [hr-example.json](./explore/hr-example.json) you will see we can create a heirarchy that includes some of our business level tags (such as application or environment), then split out the compoents with a node for each component type such as os-linux.

![Business tag hierarchy](docs/telegraf-service-explore.png "Business tag hierarchy")


## Stack Linking 
Once you have decided on the key tag dimensions to build your hierarchy you can work on stack linking custom content. 

Two example hierarchies and upload scripts can be found in the ./explore folder.

Ideally we would start with base level node home dashbaord say for a linux host or database instance. This should be stack linked to the lowest level such as _sourcehost. Here is an example [linux home page](dashboards/1-linux-host-overview.json) for any os-linux component instance.

Next you can create more high level views to stack to higher levels of the hierarchy. For example the [topn](dashboards/2-linux-top-n.json) will show just the highest cpu nodes , fullest disk volumes etc.

This can then be [stack linked](https://help.sumologic.com/Visualizations-and-Alerts/Dashboard_(New)/Link_a_dashboard_to_Explore) to the component level.

An example is this dashboard: [dashboards/1-linux-host.json](dashboards/1-linux-host.json) which is a generic linux host dashboard to use as a home page for a single os-linux entity.

You can then build and stack link higher level views that might show say per service or per environment summaries for all components you are deploying.

At higher levels of the tree we can stack link other custom dashboards such as at the 'top n' dashboard linked to os-linux component level that shows top usage of disk cpu etc across all os-linux nodes. [dashboards/2-linux-top-n.json](dashboards/2-linux-top-n.json)

Stack linking is done via the UI or by updating the JSON for the dashboard.

![Stack link base node](docs/stacklink-hostlevel.png "Stack link base node")

![higher level stack link](docs/stacklink.png "higher level stack link")

Note - you can't always stack link a single type of dashboard to multiple levels of a multi level hierarchy so you might need to create duplicates of the same dashboard with different stack link values.


# Integrating Existing Content Into the New Hierarchy Tree
Some sumo apps already exist for various telegraf plugins but they might not work out of the box with our new hierarchy. This is because the template parameters have to match exactly the names we use to map out each hierarchy level. 

So for example for redis if we are using this:
```
{
                "condition": "database",
                "level": {
                    "entityType": "db_system",
                    "nextLevelsWithConditions": [{
                        "condition": "redis",
                        "level": {
                            "entityType": "_sourcehost",
                            "nextLevelsWithConditions": [],
                            "nextLevel": null
                        }
                    }],
                    "nextLevel": null
                }
            }       
```

We need to modify the sumo app dashboards to use these template variables:
- component=redis
- db_system=redis
- _sourcehost

Let's work through fixing up some of the redis content.

## Walkthrough - convert the redis overview dasbhoard to work with the new hierarchy

First go to app catalog and import the app into your library folder as a new version with a new name.

On the import screen make surce to use 
```component=database db_system=redis``` as the filter.

Now export the json of a dashbooard you want to fix up and let's get to work!

### fixing host to _sourcehost param
metrics have a host value but logs have a _sourcehost. Earlier you might have noticed we tweaked the template to also send a _sourcehost value so we have a common host name across both.

in the redis-overview we start with this 
```
        {
            "id": null,
            "name": "host",
            "displayName": "host",
            "defaultValue": "*",
            "sourceDefinition": {
                "variableSourceType": "MetadataVariableSourceDefinition",
                "filter": "metric=redis* db_system=redis component=database db_cluster={{db_cluster}}",
                "key": "host"
            },
            "allowMultiSelect": false,
            "includeAllOption": true,
            "hideFromUI": false
        }
```

update this to:
```
        {
            "id": null,
            "name": "_sourcehost",
            "displayName": "_sourcehost",
            "defaultValue": "*",
            "sourceDefinition": {
                "variableSourceType": "MetadataVariableSourceDefinition",
                "filter": "_sourcecategory=metrics/telegraf metric=redis*",
                "key": "_sourcehost"
            },
            "allowMultiSelect": false,
            "includeAllOption": true,
            "hideFromUI": false
        }
```

### fixing sourcehost in panels
Right now the query panels would be something like this:
```
"queryString": " db_cluster={{db_cluster}} host={{host}} component=database db_system=redis  metric=redis_keyspace_hitrate | avg by host",
```

do a global replace to replace in all panels 
```host={{host}} ``` with ```_sourcehost={{_sourcehost}} ```

### fix up the stack linking.
Say we want this overview to appear at the componet redis level in the tree we would update the
```
    "topologyLabelMap": {
        "data": {
            "component": [
                "database"
            ],
            "db_system": [
                "redis"
            ]
        }
    },
```

## Creating a redis _sourcehost node dashboard
We also need a host level redis home page dashboard for metrics.

Let's pick the 'Redis - Cluster Operations' dash and convert that.

Once again:
- update the host to _sourcehost parameter block
- do a global replace to replace in all panels 
```host={{host}} ``` with ```_sourcehost={{_sourcehost}} ``` 

this time stack link to the specific lowerlevel of the tree for any sourcehost.
```
    "topologyLabelMap": {
        "data": {
            "component": [
                "database"
            ],
            "db_system": [
                "redis"
            ],
            "_sourcehost": [
                "*"
            ]
        }
    },
```