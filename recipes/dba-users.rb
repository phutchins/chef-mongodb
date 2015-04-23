include_recipe "users::dba"
node.set["sudo"]["groups"] = %w<dba>
include_recipe "sudo"
