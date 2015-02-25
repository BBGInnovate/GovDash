Chef::Log.info("deploy/before_migrate.rb Create sym links")

application=node[:deploy].keys[0]
deploy = node[:deploy][application]
current_path = "#{release_path}"
shared_path = "#{new_resource.deploy_to}/shared"

# do nothing for now
template "#{deploy[:deploy_to]}/shared/config/email.yml" do
    source "email.yml.erb"
    cookbook 'rails'
    mode "0660"
    group deploy[:group]
    owner deploy[:user]
    variables(
      :email => deploy[:email] || {},
      :environment => deploy[:rails_env]
    )
end