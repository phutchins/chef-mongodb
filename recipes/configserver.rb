#
# Cookbook Name:: chef-mongodb
# Recipe:: configserver
#

include_recipe cookbook_name

advert = [node["project"], node["site"], "mongodb", "configserver"].join("-")
advertise(advert, :port => node["mongodb"]["port"])

node.set["mongodb"]["type"]["configserver"] = true

# we are not starting the configserver service with the --configsvr
# commandline option because right now this only changes the port it's
# running on, and we are overwriting this port anyway.
mongodb_instance "configserver" do
  mongodb_type "configserver"
  port         node['mongodb']['port']
  logpath      node['mongodb']['logpath']
  dbpath       node['mongodb']['dbpath']
  enable_rest  node['mongodb']['enable_rest']
end
