#
# this callback is used in Opsworks Apps Deploy action
#
Chef::Log.info("deploy/before_migrate.rb Create sym links")

# include_recipe "rails::myconfigure"

node[:deploy].each do |application, deploy|
  deploy = node[:deploy][application]
  execute "restart Rails app #{application}" do
    cwd deploy[:current_path]
    command node[:opsworks][:rails_stack][:restart_command]
    action :nothing
  end

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

  template "#{deploy[:deploy_to]}/shared/config/facebook.yml" do
    source "facebook.yml.erb"
    cookbook 'rails'
    mode "0660"
    group deploy[:group]
    owner deploy[:user]
    variables(
      :facebook => deploy[:facebook] || {},
      :environment => deploy[:rails_env]
    )
  end

  template "#{deploy[:deploy_to]}/shared/config/rabbit.yml" do
    source "rabbit.yml.erb"
    cookbook 'rails'
    mode "0660"
    group deploy[:group]
    owner deploy[:user]
    variables(
      :rabbit => deploy[:rabbit] || {},
      :environment => deploy[:rails_env]
    )
  end
  
  template "#{deploy[:deploy_to]}/shared/config/s3.yml" do
    source "s3.yml.erb"
    cookbook 'rails'
    mode "0660"
    group deploy[:group]
    owner deploy[:user]
    variables(
      :s3 => deploy[:s3] || {},
      :environment => deploy[:rails_env]
    )
  end
  
  template "#{deploy[:deploy_to]}/shared/config/sitecatalyst.yml" do
    source "sitecatalyst.yml.erb"
    cookbook 'rails'
    mode "0660"
    group deploy[:group]
    owner deploy[:user]
    variables(
      :sitecatalyst => deploy[:sitecatalyst] || {},
      :environment => deploy[:rails_env]
    )
  end
  
  template "#{deploy[:deploy_to]}/shared/config/twitter.yml" do
    source "twitter.yml.erb"
    cookbook 'rails'
    mode "0660"
    group deploy[:group]
    owner deploy[:user]
    variables(
      :twitter => deploy[:twitter] || {},
      :environment => deploy[:rails_env]
    )
  end
  
  template "#{deploy[:deploy_to]}/shared/config/youtube.yml" do
    source "youtube.yml.erb"
    cookbook 'rails'
    mode "0660"
    group deploy[:group]
    owner deploy[:user]
    variables(
      :youtube => deploy[:youtube] || {},
      :environment => deploy[:rails_env]
    )
  end
  
  template "#{deploy[:deploy_to]}/current/config/initializers/secret_token.rb" do
    source "secret_token.rb.erb"
    cookbook 'rails'
    mode "0660"
    group deploy[:group]
    owner deploy[:user]
    
    notifies :run, "execute[restart Rails app #{application}]"
    
  end
end

  