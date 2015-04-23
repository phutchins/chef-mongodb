#
# Cookbook Name:: mongodb
# Definition:: mongodb
#
# Copyright 2011, edelight GmbH
# Authors:
#       Markus Korn <markus.korn@edelight.de>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'json'

class Chef::ResourceDefinitionList::MongoDB

  def self.configure_replicaset(node, instance_name, name, members)
    # lazy require, to move loading this modules to runtime of the cookbook
    require 'rubygems'
    require 'mongo'

    if members.length == 0
      if Chef::Config[:solo]
        abort("Cannot configure replicaset '#{name}', no member nodes found")
      else
        Chef::Log.warn("Cannot configure replicaset '#{name}', no member nodes found")
        Chef::Log.warn("If this is your first chef run and you want a one member replicaset, run chef-client again")
        return
      end
    end
    
    begin
      connection = Mongo::Connection.new('localhost', node[instance_name]['port'], :op_timeout => 5, :slave_ok => true)
    rescue
      Chef::Log.warn("Could not connect to database: 'localhost:#{node[instance_name]['port']}'")
      return
    end
    
    rs_members = []
    arbiters = []
    hidden = []
    missing_attributes = false
    priority = node["mongodb"]["priority"]

    # Create replicaset config from the members found in our search
    Chef::Log.info("Instance Name: " + instance_name)
    members.each_index do |n|
      if members[n][instance_name].nil?
        Chef::Log.info("Instance #{instance_name} does not have any attributes set on #{members[n]['fqdn']}")
        port = node[instance_name]['port']
        missing_attributes = true
      else
        port = members[n][instance_name]['port']
        if (!members[n][instance_name]['priority'].nil?)
          priority = members[n][instance_name]['priority']
        end
        if (!members[n][instance_name]["type"].nil? && !members[n][instance_name]["type"]["arbiter"].nil?)
          rs_members << {"_id" => n, "host" => "#{members[n]['fqdn']}:#{port}", :arbiterOnly => true, :priority => priority}
          arbiters << "#{members[n]['fqdn']}:#{port}"
        elsif (!members[n][instance_name]["type"].nil? && !members[n][instance_name]["type"]["hidden"].nil?)
          rs_members << {"_id" => n, "host" => "#{members[n]['fqdn']}:#{port}", :hidden => true, :priority => 0}
          hidden << "#{members[n]['fqdn']}:#{port}"
        else
          rs_members << {"_id" => n, "host" => "#{members[n]['fqdn']}:#{port}", :priority => priority}
        end
      end
    end

    if missing_attributes
      return
    end

    Chef::Log.info(
      "Configuring replicaset with members #{members.collect{ |n| n['fqdn'] }.join(', ')}"
    )
    
    # Get IP's of members found in our search
    rs_member_ips = []
    members.each_index do |n|
      if !members[n][instance_name].nil?
        port = members[n][instance_name]['port']
        rs_member_ips << {"_id" => n, "host" => "#{members[n]['ipaddress']}:#{port}"}
      end
    end
    
    # Open connection to mongo and attempt to initiate the replicaset using the config we generated
    admin = connection['admin']
    cmd = BSON::OrderedHash.new
    cmd['replSetInitiate'] = {
        "_id" => name,
        "members" => rs_members
    }

    # Check the response from the command we ran against mongo
    begin
      result = admin.command(cmd, :check_response => false)
    rescue Mongo::OperationTimeout
      Chef::Log.info("Started configuring the replicaset, this will take some time, another run should run smoothly")
      return
    end
    if result.fetch("ok", nil) == 1
      Chef::Log.info("Replicaset is OK.")
      # everything is fine, do nothing
    elsif result.fetch("errmsg", nil).include?("is already initiated")
      Chef::Log.info("This node has no configuration and the replicaset '#{name}' has already been initiated elsewhere.")
      # node can not be initiated becuase another member in the set has already initiated
    elsif result.fetch("errmsg", nil).include?("local.oplog.rs is not empty")
      Chef::Log.info("Replicaset configuration and possibly data exist on this node so we will not initiate.")
    elsif result.fetch("errmsg", nil) == "already initialized"
      # check if both configs are the same
      config = connection['local']['system']['replset'].find_one({"_id" => name})

      config_rs_members = config['members'].collect{ |a| a['host'] }
      config_rs_members = config_rs_members.sort
      search_rs_members = rs_members.collect{ |a| a['host'] }
      search_rs_members = search_rs_members.sort
      ip_rs_members = rs_member_ips.collect{ |a| a['host'] }
      ip_rs_members = ip_rs_members.sort

      # Compare replicaset name and replicaset members to see if the set is up to date
      # Later I will add checks to see if node type or priority has changed
      if config['_id'] == name and config_rs_members == search_rs_members
        # config is up-to-date, do nothing
        Chef::Log.info("Replicaset '#{name}' OK")
      elsif config['_id'] == name and config_rs_members == ip_rs_members
        # config is up-to-date, but ips are used instead of hostnames, change config to hostnames
        Chef::Log.info("Need to convert ips to hostnames for replicaset '#{name}'")
        old_members = config['members'].collect{ |m| m['host'] }
        mapping = {}
        rs_member_ips.each do |mem_h|
          members.each do |n|
            ip, prt = mem_h['host'].split(":")
            if ip == n['ipaddress']
              mapping["#{ip}:#{prt}"] = "#{n['fqdn']}:#{prt}"
            end
          end
        end
        config['members'].collect!{ |m| {"_id" => m["_id"], "host" => mapping[m["host"]]} }
        config['version'] += 1
        
        rs_connection = Mongo::ReplSetConnection.new( *old_members.collect{ |m| m.split(":") })
        admin = rs_connection['admin']
        cmd = BSON::OrderedHash.new
        cmd['replSetReconfig'] = config
        result = nil
        begin
          result = admin.command(cmd, :check_response => false)
        rescue Mongo::ConnectionFailure
          # reconfiguring destroys exisiting connections, reconnect
          Mongo::Connection.new('localhost', node[instance_name]['port'], :op_timeout => 5, :slave_ok => true)
          config = connection['local']['system']['replset'].find_one({"_id" => name})
          Chef::Log.info("New config successfully applied: #{config.inspect}")
        end
        if !result.nil?
          Chef::Log.error("configuring replicaset returned: #{result.inspect}")
        end
      else
        # Something in the replicaset has changed
        # Remove removed members from the replicaset and add the new ones
        max_id = config['members'].collect{ |member| member['_id']}.max
        rs_member_nodes = rs_members
        rs_members.collect!{ |member| member['host'] }
        config['version'] += 1
        old_members = config['members'].collect{ |member| member['host'] }
        if node['mongodb']['auto_remove_replset_members']
          members_delete = old_members - rs_members
          if !members_delete.empty?
            Chef::Log.info("Removing members: #{members_delete.inspect}")
          end
          config['members'] = config['members'].delete_if{ |m| members_delete.include?(m['host']) }
        else
          Chef::Log.info("Nodes disappeared but not removing. To autoremove, set node['mongodb']['auto_remove_replset_members'] to true")
        end
        members_add = rs_members - old_members
        if !members_add.empty?
          Chef::Log.info("Found new members: #{members_add.inspect}")
        end
        # Create the new replicaset config and set any new nodes id higher than the highest existing
        members_add.each do |m|
          max_id += 1
          members.each do |n|
            if ("#{n['fqdn']}:#{n['mongodb']['port']}" == m)
              if (!n[instance_name]['priority'].nil?)
                priority = n[instance_name]['priority']
              end
            end
          end
          Chef::Log.info("Priority: #{priority}")
          if arbiters.include?(m)
            Chef::Log.info("Adding new member #{m} with id #{max_id} as Arbiter")
            config['members'] << {"_id" => max_id, "host" => m, :arbiterOnly => true, "priority" => priority}
          elsif hidden.include?(m)
            Chef::Log.info("Adding new member #{m} with id #{max_id} as Hidden Secondary")
            config['members'] << {"_id" => max_id, "host" => m, :hidden => true, "priority" => 0}
          else
            Chef::Log.info("Adding new member #{m} with id #{max_id} as Replica")
            config['members'] << {"_id" => max_id, "host" => m, :priority => priority}
          end
        end

        # Use the old member or members in the set to make a connection
        rs_connection = Mongo::ReplSetConnection.new( old_members )
        admin = rs_connection['admin']

        cmd = BSON::OrderedHash.new
        cmd['replSetReconfig'] = config

        result = nil
        begin
          result = admin.command(cmd, :check_response => false)
          Chef::Log.debug("Mongo CMD: #{cmd}")
        rescue Mongo::ConnectionFailure
          # reconfiguring destroys exisiting connections, reconnect
          Mongo::Connection.new('localhost', node[instance_name]['port'], :op_timeout => 5, :slave_ok => true)
          config = connection['local']['system']['replset'].find_one({"_id" => name})
          Chef::Log.info("New config successfully applied: #{config.inspect}")
        end
        if !result.nil?
          if !result.fetch('ok', nil).nil?
            Chef::Log.info("Replicaset OK")
          else
            Chef::Log.error("Configuring replicaset returned: #{result.inspect}")
          end
        end
      end
    elsif !result.fetch("errmsg", nil).nil?
      Chef::Log.error("Failed to configure replicaset, reason: #{result.inspect}")
    end
  end
  
  def self.configure_shards(node, instance_name, shard_nodes)
    # lazy require, to move loading this modules to runtime of the cookbook
    require 'rubygems'
    require 'mongo'
    
    shard_groups = Hash.new{|h,k| h[k] = []}
    
    shard_nodes.each do |n|
      # Use cluster_name and Shard_name to create a shard group key unique to each shard cluster
      if (!n[instance_name]['type'].nil? && !n[instance_name]['type']['replicaset'].nil?)
        key = "#{n[instance_name]['cluster_name']}_#{n[instance_name]['shard_name']}"
      else
        key = '_single'
      end
      shard_groups[key] << "#{n['fqdn']}:#{n[instance_name]['port']}"
    end
    Chef::Log.info(shard_groups.inspect)
    
    shard_members = []
    shard_groups.each do |name, members|
      if name == "_single"
        shard_members += members
      else
        shard_members << "#{name}/#{members.join(',')}"
      end
    end
    Chef::Log.info(shard_members.inspect)
    
    begin
      connection = Mongo::Connection.new('localhost', node[instance_name]['port'], :op_timeout => 5)
    rescue Exception => e
      Chef::Log.warn("Could not connect to database: 'localhost:#{node[instance_name]['port']}', reason #{e}")
      return
    end
    
    admin = connection['admin']
    
    shard_members.each do |shard|
      cmd = BSON::OrderedHash.new
      cmd['addShard'] = shard
      begin
        result = admin.command(cmd, :check_response => false)
      rescue Mongo::OperationTimeout
        result = "Adding shard '#{shard}' timed out, run the recipe again to check the result"
      end
      Chef::Log.info(result.inspect)
    end
  end
  
  def self.configure_sharded_collections(node, instance_name, sharded_collections)
    # lazy require, to move loading this modules to runtime of the cookbook
    require 'rubygems'
    require 'mongo'
    
    begin
      connection = Mongo::Connection.new('localhost', node[instance_name]['port'], :op_timeout => 5)
    rescue Exception => e
      Chef::Log.warn("Could not connect to database: 'localhost:#{node[instance_name]['port']}', reason #{e}")
      return
    end
    
    admin = connection['admin']
    
    databases = sharded_collections.keys.collect{ |x| x.split(".").first}.uniq
    Chef::Log.info("enable sharding for these databases: '#{databases.inspect}'")
    
    databases.each do |db_name|
      cmd = BSON::OrderedHash.new
      cmd['enablesharding'] = db_name
      begin
        result = admin.command(cmd, :check_response => false)
      rescue Mongo::OperationTimeout
        result = "enable sharding for '#{db_name}' timed out, run the recipe again to check the result"
      end
      if result['ok'] == 0
        # some error
        errmsg = result.fetch("errmsg")
        if errmsg == "already enabled"
          Chef::Log.info("Sharding is already enabled for database '#{db_name}', doing nothing")
        else
          Chef::Log.error("Failed to enable sharding for database #{db_name}, result was: #{result.inspect}")
        end
      else
        # success
        Chef::Log.info("Enabled sharding for database '#{db_name}'")
      end
    end
    
    sharded_collections.each do |name, key|
      cmd = BSON::OrderedHash.new
      cmd['shardcollection'] = name
      cmd['key'] = {key => 1}
      begin
        result = admin.command(cmd, :check_response => false)
      rescue Mongo::OperationTimeout
        result = "sharding '#{name}' on key '#{key}' timed out, run the recipe again to check the result"
      end
      if result['ok'] == 0
        # some error
        errmsg = result.fetch("errmsg")
        if errmsg == "already sharded"
          Chef::Log.info("Sharding is already configured for collection '#{name}', doing nothing")
        else
          Chef::Log.error("Failed to shard collection #{name}, result was: #{result.inspect}")
        end
      else
        # success
        Chef::Log.info("Sharding for collection '#{result['collectionsharded']}' enabled")
      end
    end
  
  end
  
end
