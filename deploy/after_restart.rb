rails_env = new_resource.environment["RAILS_ENV"]
links = "rm config/email.yml; ln -s ../shared/config/email.yml config/email.yml;"
links << "rm config/facebook.yml;ln -s ../shared/config/facebook.yml config/facebook.yml;"
links << "rm config/rabbit.yml;ln -s ../shared/config/rabbit.yml config/rabbit.yml;"
links << "rm config/twitter.yml;ln -s ../shared/config/twitter.yml config/twitter.yml;"
links << "rm config/s3.yml;ln -s ../shared/config/s3.yml config/s3.yml;"
links << "rm  config/sitecatalyst.yml;ln -s ../shared/config/sitecatalyst.yml config/sitecatalyst.yml;"
links << "rm config/database.yml;ln -s ../shared/config/database.yml config/database.yml;"
Chef::Log.info("Start deplayed_job for RAILS_ENV=#{rails_env}...")
=begin
execute "deplayed_job start" do
  cwd release_path
  command "bin/delayed_job restart"
  environment "RAILS_ENV" => rails_env
  action :nothing
end
=end

Chef::Log.info("Create sym links")
run <<-END
  cwd release_path
  current_path = '#{release_path}/current'
  shared_path = '#{release_path}/shared'
  rm '#{current_path}/config/email.yml'
  rm '#{current_path}/config/facebook.yml'
  rm '#{current_path}/config/rabbit.yml'
  rm '#{current_path}/config/twitter.yml'
  rm '#{current_path}/config/s3.yml'
  rm '#{current_path}/config/sitecatalyst.yml'
  ln -s '#{shared_path}/config/email.yml #{current_path}/config/email.yml'
  ln -s '#{shared_path}/config/facebook.yml #{current_path}/config/facebook.yml'
  ln -s '#{shared_path}/config/rabbit.yml #{current_path}/config/rabbit.yml'
  ln -s '#{shared_path}/config/twitter.yml #{current_path}/config/twitter.yml'
  ln -s '#{shared_path}/config/s3.yml #{current_path}/config/s3.yml'
  ln -s '#{shared_path}/config/sitecatalyst.yml #{current_path}/config/sitecatalyst.yml'
  bin/delayed_job restart
END


