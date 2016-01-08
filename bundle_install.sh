#!/bin/bash

source /home/uberdash/.rvm/scripts/rvm
rake=/home/uberdash/.rvm/gems/ruby-2.2.1/bin/rake
bundle=/home/uberdash/.rvm/gems/ruby-2.2.1/bin/bundle

root=/home/uberdash/socialdash_app
current_path="${root}/current"
shared_path="${root}/shared"
release_path="$root/releases"

export RAILS_ENV=production

# $bundle exec bundle install --path=/home/deploy/.bundler/socialdash_app --without=test development
$bundle install --without=test development
${rake} db:migrate
touch tmp/restart.txt
    