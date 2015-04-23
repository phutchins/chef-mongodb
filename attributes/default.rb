#
# Cookbook Name:: chef-mongodb
# Attributes:: default
#

default["mongodb"]["dbpath"] = "/data"
default["mongodb"]["logpath"] = "/var/log/mongodb"
default["mongodb"]["bind_ip"] = nil
default["mongodb"]["port"] = 27017
default["mongodb"]["package"] = "mongodb-10gen"
default["mongodb"]["version"] = '2.2.0'
default["mongodb"]["maxconns"] = 1638

# cluster identifier
default["mongodb"]["client_roles"] = []
default["mongodb"]["cluster_name"] = nil
default["mongodb"]["replicaset_name"] = nil
default["mongodb"]["shard_name"] = "default"
default["mongodb"]["priority"] = 1
default["mongodb"]["enable_rest"] = false
default["mongodb"]["enable_fork"] = false
default["mongodb"]["user"] = "mongodb"
default["mongodb"]["group"] = "mongodb"
default["mongodb"]["root_group"] = "root"
default["mongodb"]["init_dir"] = "/etc/init.d"
default["mongodb"]["init_script_template"] = "mongodb.init.erb"

case node["platform"]
when "freebsd"
  default["mongodb"]["defaults_dir"] = "/etc/rc.conf.d"
  default["mongodb"]["init_dir"] = "/usr/local/etc/rc.d"
  default["mongodb"]["root_group"] = "wheel"
  default["mongodb"]["package_name"] = "mongodb"

when "centos","redhat","fedora","amazon","scientific"
  default["mongodb"]["defaults_dir"] = "/etc/sysconfig"
  default["mongodb"]["package_name"] = "mongo-10gen-server"
  default["mongodb"]["user"] = "mongod"
  default["mongodb"]["group"] = "mongod"
  default["mongodb"]["init_script_template"] = "redhat-mongodb.init.erb"

else
  default["mongodb"]["config_dir"] = "/etc"
  default["mongodb"]["config_template"] = "mongodb.conf.erb"
  default["mongodb"]["upstart_config_dir"] = "/etc/init"
  default["mongodb"]["upstart_template"] = "mongodb.upstart.erb"
  default["mongodb"]["defaults_dir"] = "/etc/default"
  default["mongodb"]["root_group"] = "root"
  default["mongodb"]["package_name"] = "mongodb-10gen"
  default["mongodb"]["apt_repo"] = "debian-sysvinit"

end
