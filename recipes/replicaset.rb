#
# Cookbook Name:: chef-mongodb
# Recipe:: replicatset
#

include_recipe "#{cookbook_name}::default"
include_recipe "espy"

node.set["mongodb"]["type"]["replicaset"] = true
node.set["mongodb"]["instances"] = ["mongodb"]

node["mongodb"]["instances"].each do |instance|
  advert = ["mongodb", node["site"], node["project"], instance].join("-")
  Chef::Log.info("Espy advertising: #{advert}")
  espy_attrs = {}
  if (!node[instance]["type"]["replicaset"].nil?) then espy_attrs["replicaset"] = true end
  if (!node[instance]["type"]["arbiter"].nil?) then espy_attrs["arbiter"] = true end
  if (!node[instance]["type"]["hidden"].nil?) then espy_attrs["hidden"] = true end
  if (!node[instance]["type"]["shard"].nil?) then espy_attrs["shard"] = true end
  if (!node[instance]["type"]["configserver"].nil?) then espy_attrs["configserver"] = true end
  if (!node[instance]["type"]["mongos"].nil?) then espy_attrs["mongos"] = true end
  if (!node[instance]["priority"].nil?) then espy_attrs["priority"] = node[instance]["priority"] end
  if (!node["hostname"].nil?) then espy_attrs["hostname"] = node["hostname"] end
  espy_attrs["port"] = node[instance]["port"]
  advertise(advert, espy_attrs)
end

# if we are configuring a shard as a replicaset we do nothing in this recipe
mongodb_instance "mongodb" do
  only_if { !node.recipe?("#{cookbook_name}::shard") }
  mongodb_type "mongod"
  port         node['mongodb']['port']
  logpath      node['mongodb']['logpath']
  dbpath       node['mongodb']['dbpath']
  replicaset   node
  enable_rest  node['mongodb']['enable_rest']
  maxconns     node['mongodb']['maxconns']
end
