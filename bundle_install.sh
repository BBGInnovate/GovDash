#!/bin/bash

source /home/uberdash/.rvm/scripts/rvm
rake=/home/uberdash/.rvm/gems/ruby-2.2.1/bin/rake
bundle=/home/uberdash/.rvm/gems/ruby-2.2.1/bin/bundle

root=/srv/www/socialdash_app
current_path="${root}/current"
shared_path="${root}/shared"
release_path="$root/releases"
name=$1

# export PATH=/usr/local/bin:$PATH
export RAILS_ENV=production
# cd $release_path/$name

# $bundle exec bundle install --path=/home/deploy/.bundler/socialdash_app --without=test development
$bundle install --without=test development
${rake} db:migrate
ln -s $release_path $current_path
touch tmp/restart.txt
    