#
# Cookbook Name:: chef-mongodb
# Recipe:: shard
#

include_recipe "#{cookbook_name}::default"
include_recipe "espy"

node.set["mongodb"]["type"]["shard"] = true
node.set["mongodb"]["instances"] = ["mongodb"]

node["mongodb"]["instances"].each do |instance|
  advert = ["mongodb", node["site"], node["project"], instance, node[instance]["shard_name"]].join("-")
  espy_attrs = {}
  if (!node[instance]["type"]["replicaset"].nil?) then espy_attrs["replicaset"] = true end
  if (!node[instance]["type"]["arbiter"].nil?) then espy_attrs["arbiter"] = true end
  if (!node[instance]["type"]["hidden"].nil?) then espy_attrs["hidden"] = true end
  if (!node[instance]["type"]["shard"].nil?) then espy_attrs["shard"] = true end
  if (!node[instance]["type"]["configserver"].nil?) then espy_attrs["configserver"] = true end
  if (!node[instance]["type"]["mongos"].nil?) then espy_attrs["mongos"] = true end
  if (!node[instance]["cluster_name"].nil?) then espy_attrs["cluster_name"] = node[instance]["cluster_name"] end
  if (!node[instance]["shard_name"].nil?) then espy_attrs["shard_name"] = node[instance]["shard_name"] end
  if (!node[instance]["priority"].nil?) then espy_attrs["priority"] = node[instance]["priority"] end
  if (!node["hostname"].nil?) then espy_attrs["hostname"] = node["hostname"] end
  espy_attrs["port"] = node[instance]["port"]
  advertise(advert, espy_attrs)
end

is_replicated = node.recipe?("#{cookbook_name}::replicaset")

# we are not starting the shard service with the --shardsvr
# commandline option because right now this only changes the port it's
# running on, and we are overwriting this port anyway.
mongodb_instance "shard" do
  mongodb_type "shard"
  port         node['mongodb']['port']
  logpath      node['mongodb']['logpath']
  dbpath       node['mongodb']['dbpath']
  if is_replicated
    replicaset    node
  end
  enable_rest  node['mongodb']['enable_rest']
  maxconns     node['mongodb']['maxconns']
end
