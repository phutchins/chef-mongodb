name              "chef-mongodb"
maintainer        "Philip Hutchins"
maintainer_email  "flipture@gmail.com"
description       "Installs and configures mongodb"
version           "0.1.10"

recipe "chef-mongodb", "Installs and configures a single node mongodb instance"
recipe "chef-mongodb::10gen_repo", "Adds the 10gen repo to get the latest packages"
recipe "chef-mongodb::mongos", "Installs and configures a mongos which can be used in a sharded setup"
recipe "chef-mongodb::configserver", "Installs and configures a configserver for mongodb sharding"
recipe "chef-mongodb::shard", "Installs and configures a single shard"
recipe "chef-mongodb::replicaset", "Installs and configures a mongodb replicaset"
recipe "chef-mongodb::multi_instance", "Installs and configures two nodes on the same host"

depends "apt"
depends "yum"

%w{ ubuntu debian freebsd centos redhat fedora amazon scientific}.each do |os|
  supports os
end

attribute "mongodb/dbpath",
  :display_name => "dbpath",
  :description => "Path to store the mongodb data",
  :default => "/var/lib/mongodb"

attribute "mongodb/logpath",
  :display_name => "logpath",
  :description => "Path to store the logfiles of a mongodb instance",
  :default => "/var/log/mongodb"

attribute "mongodb/port",
  :display_name => "Port",
  :description => "Port the mongodb instance is running on",
  :default => "27017"

attribute "mongodb/client_roles",
  :display_name => "Client Roles",
  :description => "Roles of nodes who need access to the mongodb instance",
  :default => []

attribute "mongodb/cluster_name",
  :display_name => "Cluster Name",
  :description => "Name of the mongodb cluster, all nodes of a cluster must have the same name.",
  :default => nil

attribute "mongodb/shard_name",
  :display_name => "Shard name",
  :description => "Name of a mongodb shard",
  :default => "default"

attribute "mongodb/sharded_collections",
  :display_name => "Sharded Collections",
  :description => "collections to shard",
  :default => {}

attribute "mongodb/replicaset_name",
  :display_name => "Replicaset_name",
  :description => "Name of a mongodb replicaset",
  :default => nil

attribute "mongodb/enable_rest",
  :display_name => "Enable Rest",
  :description => "Enable the ReST interface of the webserver"

attribute "mongodb/bind_ip",
  :display_name => "Bind address",
  :description => "MongoDB instance bind address",
  :default => nil
