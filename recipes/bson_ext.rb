execute "apt-get update" do
  action :nothing
end.run_action(:run)

%w<gcc make>.each do |my_package|
  package my_package do
    action :nothing
  end.run_action(:install)
end

%w<bson_ext>.each do |gem|
  gem_package gem do
    action :nothing
  end.run_action(:install)
end

Gem.clear_paths

chef_gem "bson_ext"
