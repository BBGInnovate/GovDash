rails_env = new_resource.environment["RAILS_ENV"]
Chef::Log.info("Start deplayed_job for RAILS_ENV=#{rails_env}...")
execute "deplayed_job start" do
  cwd release_path
  command "bin/delayed_job restart"
  environment "RAILS_ENV" => rails_env
  action :nothing
end
