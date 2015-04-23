#
# Cookbook Name:: chef-mongodb
# Recipe:: multi_instance
#

include_recipe cookbook_name
include_recipe "espy"

node.set["mongodb"]["type"]["replicaset"] = true
node.set["mongodb"]["instances"] = [ 'mongodb-27017', 'mongodb-27018' ]

node["mongodb"]["instances"].each do |instance|
  advert = ["mongodb", node["site"], node["project"], instance].join("-")
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


mongodb_instance 'mongodb-27017' do
  mongodb_type "mongod"
  port         node['mongodb-27017']['port']
  logpath      node['mongodb']['logpath']
  dbpath       node['mongodb']['dbpath']
  replicaset   node
  enable_rest  node['mongodb']['enable_rest']
  maxconns     node['mongodb']['maxconns']
end

mongodb_instance 'mongodb-27018' do
  mongodb_type "mongod"
  port         node['mongodb-27018']['port']
  logpath      node['mongodb']['logpath']
  dbpath       node['mongodb']['dbpath']
  replicaset   node
  enable_rest  node['mongodb']['enable_rest']
  maxconns     node['mongodb']['maxconns']
end
