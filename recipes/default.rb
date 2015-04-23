#
# Cookbook Name:: chef-mongodb
# Recipe:: default
#

include_recipe "#{cookbook_name}::bson_ext"

mongo_init_file = '/etc/init/mongodb.conf'
mongo_initd_file = '/etc/init.d/mongodb'


package node["mongodb"]["package_name"] do
  if !node['mongodb']['version'].nil?
    version node['mongodb']['version']
  end
  action :install
  notifies :run, "bash[stop_initd_mongo]", :immediately
  notifies :delete, "file[#{mongo_initd_file}]", :immediately
end

# Need to set this up to detect OS and use appropriate service for each
bash "stop_initd_mongo" do
  only_if { ::File.exists?('/etc/init.d/mongodb') }
  user "root"
  code <<-EOH
  /etc/init.d/mongodb stop
  EOH
  action :nothing
end

service "mongodb" do
  provider Chef::Provider::Service::Upstart
  supports :status => true, :restart => true, :disable => true, :stop => true, :start => true
  action :nothing
end

file mongo_initd_file do
  action :nothing
end

gem_package 'mongo' do
  action :nothing
end.run_action(:install)
Gem.clear_paths

if node["recipes"].include?("#{cookbook_name}::default") or node["recipes"].include?(cookbook_name)
  # configure default instance
  node.set["mongodb"]["type"]["singleton"] = true
  mongodb_instance "mongodb" do
    mongodb_type "mongod"
    bind_ip      node["mongodb"]["bind_ip"]
    port         node["mongodb"]["port"]
    logpath      node["mongodb"]["logpath"]
    dbpath       node["mongodb"]["dbpath"]
    enable_rest  node["mongodb"]["enable_rest"]
    maxconns     node["mongodb"]["maxconns"]
  end
end
