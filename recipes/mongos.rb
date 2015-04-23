#
# Cookbook Name:: chef-mongodb
# Recipe:: mongos
#

include_recipe cookbook_name

advert = [node["project"], node["site"], "mongodb", "mongos"].join("-")
advertise(advert, :port => node["mongodb"]["port"])

node.set["mongodb"]["type"]["mongos"] = true

# Replacing search with ESPY for finding the config server(s)
#configsrv = search(
#  :node,
#  "mongodb_cluster_name:#{node['mongodb']['cluster_name']} AND \
#   type:configserver"
#)

advert_configserver = [node["project"], node["site"], "mongodb", "configserver"].join("-")
configsrv = advert_configserver

if configsrv.length != 1 and configsrv.length != 3
  Chef::Log.error("Found #{configsrv.length} configserver, need either one or three of them")
  raise "Wrong number of configserver nodes"
end

mongodb_instance "mongos" do
  mongodb_type "mongos"
  port         node['mongodb']['port']
  logpath      node['mongodb']['logpath']
  dbpath       node['mongodb']['dbpath']
  configserver configsrv
  enable_rest  node['mongodb']['enable_rest']
  maxconns     node['mongodb']['maxconns']
end
