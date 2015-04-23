# DESCRIPTION:

Installs and configures MongoDB, supporting:

* Single MongoDB
* Replication
* Sharding
* Replication and Sharding
* MongoDB repository package installation

# REQUIREMENTS:

## Platform:

This cookbook was written for Ubuntu and has been tested on 10.04 and 12.04. It currently
uses upstart but I aim to configure this to be multiplatform down the road.

# DEFINITIONS:

This cookbook contains a definition `mongodb_instance` which can be used to configure
a certain type of mongodb instance, like the default mongodb or various components
of a sharded setup.

For examples see the USAGE section below.

# RECIPES
* 10gen_repo.rb - Adds the 10gen repositories to apt for retrieving the archive
* arbiter.rb - Sets the node type to arbiter true
* bson_ext.rb - Adds the BSON gem which is used for packing mongodb data
* configserver.rb - Sets the node type to configserver true
* default.rb - Installs the mongodb package, removes the stock init scripts, installs
    the mongo gem, and sets up a default instance of mongo if the default recipe is
    directly assigned.
* hidden.rb - Sets the node type to hidden
* mongos.rb - Sets the node type to mongos
* multi_instance.rb - Sets up a node with two instances of mongodb on ports
    27017 and 27018.
* replicaset.rb - Sets the node type to replicaset and creates a mongodb instance
* shard.rb - Sets the node type to shard and creates a mongodb instance

# ATTRIBUTES:

## Basic:
* `mongodb[:package_name]` - Sets the name of the package that will be installed with apt
* `mongodb[:version]` - Sets the version of the mongodb package you would like to install
* `mongodb[:dbpath]` - Location for mongodb data directory, defaults to "/var/lib/mongodb"
* `mongodb[:logpath]` - Path for the logfiles, default is "/var/log/mongodb"
* `mongodb[:port]` - Port the mongod listens on, default is 27017
* `mongodb[:cluster_name]` - Name of the cluster, all members of the cluster must
    reference to the same name, as this name is used internally to identify all
    members of a cluster.
* `mongodb[:shard_name]` - Name of a shard, default is "default"
* `mongodb[:sharded_collections]` - Define which collections are sharded
* `mongodb[:replicaset_name]` - Define name of replicatset

## Types
* `mongodb[:type][:replicaset]` - Set to true to enable replicaset on a node, default unset
* `mongodb[:type][:hidden]` - Sets a node to hidden. Node will get updates but
    will not serve traffic
* `mongodb[:type][:arbiter]` - Sets a node to arbiter. Node must have replication enabled
* `mongodb[:type][:mongos]` - Sets a node type to mongos. Used for sharding.
* `mongodb[:type][:configserver]` - Sets a nodes type to configserver. Used for sharding.
* `mongodb[:type][:mongod]` - This is the default type. Sets the node to mongodb daemon.
* `mongodb[:type][:singleton]` - Sets a node to type singleton. If default recipe alone is
    used, this is the type that is set.

## Extended
* `mongodb[:priority]` - Set the priority of a node in a replicaset, default is 1
* `mongodb[:enable_rest]` - Enable the rest interface, default is false
* `mongodb[:maxconns]` - Set the max connections on the node, default is 1638

# USAGE

## Wrapper Cookbook
This cookbook was written with the intent of using a wrapper cookbook to interface with it. Take a look
at chef-mongodb-wrapper for specifics on how to impliment the wrapper.

### Wrapper functionality
* `default.rb` - Adds the apt recipe, monitoring and log-maintenance
* `apt.rb` - Adds APT repository for an ubuntu host
* `replset-namegen.rb` - Auto generates replicaset names based on scope, project, site and more if needed.
* `monitoring.rb` - Enables the mongo_ck.sh script which logs to syslog for Zenoss
* `log-maintenance.rb` - Enables cron jobs to run the log rotation script and clean up logs older than 5 days
* `relicaset.rb` - Sets up a replicaset node
* `node-priority-[0-3].rb` - Sets the priority of a node for voting members of a replicaset
* `multi_instance.rb` - Used for setting up two instances of mongodb on one host. The instances will
    use port 27017 and 27018.

## Apt repository
APT repositories are assigned by including either the 10gen_repo recipe in this cookbook, or using
    the apt recipe in the mongodb-wrapper cookbook. You will need to assign the package_name attribute
    if you want something other than the default for each.

## Single mongodb instance
Simply assign the cookbooks default recipe and one of the apt recipes to the node or inside of
  your wrapper recipe.

* `recipe[:mongodb::10gen_repo]`
* `recipe[chef-mongodb]`

For the wrappers APT recipe you would go through the wrapper for the apt
    recipe and directly to the chef-mongodb cookbook to get the default recipe.

* `recipe[mongodb-wrapper::apt]`
* `recipe[chef-mongodb]`

## Replicasets
For replicasets you should go through the wrapper as follows.

* `recipe[mongodb-wrapper]`
* `recipe[mongodb-wrapper::replicaset]`

## Sharding
Currently there is no wrapper recipe set up for sharding. You will need to assign the default recipe
    along with the appropriate recipe for the type of node you are setting up. Assign a shard_name
    attribute for each of the mongod hosts shard cluster. You can use replset-namegen recipe to
    automatically set up the replicaset shard names using the shard_name you assigned. The cookbook
    uses this shard name to find each group of nodes for a shard.

### Set in your recipe:
* `mongodb[:shard_name] = "ShardName1"`

### Assign to node or in recipe that is assigned to node:
Shard Node

* `recipe[mongodb-wrapper::replset-namegen]`
* `recipe[chef-mongodb::shard]`

Mongos Node

* `recipe[mongodb-wrapper::replset-namegen]`
* `recipe[chef-mongodb::mongos]`

Config Server

* `recipe[mongodb-wrapper::replset-namegen]`
* `recipe[chef-mongodb::configserver]`


## Sharding + Replication
To enable replication on your shard nodes, simply add the replicaset recipe along with shard
    and replset-namegen

* `recipe[mongodb-wrapper::replicaset]`
