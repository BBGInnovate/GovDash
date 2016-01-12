#!/bin/bash

source /home/uberdash/.rvm/scripts/rvm
rake=/home/uberdash/.rvm/rubies/ruby-2.2.1/bin/rake
bundle=/home/uberdash/.rvm/gems/ruby-2.2.1/bin/bundle

root=/home/uberdash/socialdash_app
current_path="${root}/current"
shared_path="${root}/shared"
release_path="$root/releases"

configs="config/database.yml config/email.yml config/facebook.yml config/rabbit.yml config/twitter.yml \
  config/youtube.yml config/s3.yml config/sitecatalyst.yml \
  log"
secret_token="config/secret_token.rb"

for j in $configs
do 
  ln -fs ${shared_path}/system public/system; \
  ln -fs ${shared_path}/$secret_token config/initializers/secret_token.rb
  ln -fs ${shared_path}/$j $j
done

export RAILS_ENV=production
# $bundle exec bundle install --path=/home/deploy/.bundler/socialdash_app --without=test development
bundle install --without=test development
rake db:migrate
rm $current_path
ln -fs $curr $current_path
cd $current_path
touch tmp/restart.txt

