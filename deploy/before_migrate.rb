Chef::Log.info("deploy/before_migrate.rb Create sym links")

application=node[:deploy].keys[0]
deploy = node[:deploy][application]
current_path = "#{release_path}"
shared_path = "#{new_resource.deploy_to}/shared"

# do nothing for now