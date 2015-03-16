rails_env = new_resource.environment["RAILS_ENV"]

Chef::Log.info("Start deplayed_job for RAILS_ENV=#{rails_env}...")
Chef::Log.info("deploy/after_restart.rb Run delayed_job")

application=node[:deploy].keys[0]
deploy = node[:deploy][application]
current_path = "#{release_path}"
shared_path = "#{new_resource.deploy_to}/shared"

run <<-END
  cwd release_path
  rm '#{current_path}/config/email.yml'
  rm '#{current_path}/config/facebook.yml'
  rm '#{current_path}/config/rabbit.yml'
  rm '#{current_path}/config/twitter.yml'
  rm '#{current_path}/config/youtube.yml'
  rm '#{current_path}/config/s3.yml'
  rm '#{current_path}/config/sitecatalyst.yml'
  rm '#{current_path}/config/initializers/secret_token.rb'
  ln -s '#{shared_path}/config/email.yml' '#{current_path}/config/email.yml'
  ln -s '#{shared_path}/config/facebook.yml' '#{current_path}/config/facebook.yml'
  ln -s '#{shared_path}/config/rabbit.yml' '#{current_path}/config/rabbit.yml'
  ln -s '#{shared_path}/config/twitter.yml' '#{current_path}/config/twitter.yml'
  ln -s '#{shared_path}/config/youtube.yml' '#{current_path}/config/youtube.yml'
  ln -s '#{shared_path}/config/s3.yml' '#{current_path}/config/s3.yml'
  ln -s '#{shared_path}/config/sitecatalyst.yml' '#{current_path}/config/sitecatalyst.yml'
  ln -s '#{shared_path}/config/secret_token.rb' '#{current_path}/config/initializers/secret_token.rb' 
  touch tmp/restart.txt  
  bin/delayed_job restart
END

=begin
link "#{release_path}/public/assets" do
   to shared_assets
end
rails_env = new_resource.environment["RAILS_ENV"]
Chef::Log.info("Precompiling assets for RAILS_ENV=#{rails_env}...")
execute "rake assets:precompile" do
  cwd release_path
  command "bundle exec rake assets:precompile"
  environment "RAILS_ENV" => rails_env
end
=end


