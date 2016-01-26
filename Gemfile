source 'https://rubygems.org'
source 'https://gems.github.com'

# ruby '2.1.5'

gem 'rake'
gem 'rack-oauth2'
# gem 'rails', '~> 4.2.0'
# gem  "activesupport"

gem 'thin'
gem 'mysql2'
# gem 'activerecord4-redshift-adapter', github: 'aamine/activerecord4-redshift-adapter'
gem 'activerecord4-redshift-adapter', github: 'khwangster/activerecord4-redshift-adapter'
# gem 'activerecord-redshift-adapter', '~> 0.9.4'

# download http://postgresapp.com/ and add it to Applications
# gem install pg -- --with-pg-config=/Applications/Postgres.app/Contents/Versions/9.4/bin/pg_config
# gem 'pg'
# gem 'Instagram'
gem 'fb_graph'
gem "koala"
# gem "aws-s3", github: 'bartoszkopinski/aws-s3'
gem 'aws-sdk', '~> 2'
gem 'yt' # , '~> 0.25.5'

gem 'language_list'
gem 'twitter', '>= 5.10.0'
gem 'oauth'
gem 'twitter_oauth'
# gem 'roo' # Open Office
gem 'therubyracer'
gem 'bunny'
gem 'amqp'
gem 'rails-observers'
# gem 'email_verifier'
# gem 'valid_email', require: ['valid_email/all_with_extensions']

gem 'daemons'
gem 'delayed_job_active_record'
# rails generate delayed_job
# RAILS_ENV=production bin/delayed_job restart
#
gem 'clockwork'
gem 'stalker'

# gem 'rabbit_jobs'

gem 'active_scaffold' #, '>= 3.4.0.rc', :path => "vendor/plugins/active_scaffold"
gem 'sass-rails'
# undefined method `environment' for nil:NilClass
# force sprockets version by adding this to gem file: 
gem 'sprockets', '=2.11.0'

#ROmniture Sitecatalyst client
#Required by custom lib/omniture.rb
gem 'romniture'

# The culprit was Heroku's rails_12factor gem
# Removing that gem from the Gemfile, now the logs are working as expected.
# group :production do
#  gem 'rails_12factor'
# end

gem 'elasticsearch', git: 'https://github.com/elasticsearch/elasticsearch-ruby.git'
gem 'elasticsearch-model', git: 'https://github.com/elasticsearch/elasticsearch-rails.git'
gem 'elasticsearch-rails', git: 'https://github.com/elasticsearch/elasticsearch-rails.git'

group :assets do
  gem 'uglifier', '>= 1.3.0'
end

gem 'bower-rails'
gem 'jquery-rails'
gem 'twitter-bootstrap-rails'
gem 'nokogiri', '~> 1.6.6.2'
gem 'devise' # , '~> 3.2'
gem 'json'

gem 'raddocs'

group :development, :test do
  gem 'rspec-rails', '~> 2.0'
  gem 'factory_girl_rails', '4.2.1'
  gem 'rspec_api_documentation'
  gem 'better_errors'
  gem 'binding_of_caller'
#  gem "letter_opener"
#  gem 'brakeman', :require => false
# gem unpack dynamics_crm --target vendor/gems
  gem 'dynamics_crm', :path => "vendor/gems/dynamics_crm-0.6.0"
end

group :test do
  gem 'faker'
  gem 'rack-test'
  gem 'turn', :require => false
  gem 'database_cleaner'
  gem 'shoulda-matchers'
  gem 'shoulda-callback-matchers', '>=0.3.0'
  gem 'json_spec'
end
