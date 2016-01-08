#!/bin/bash

rake=/usr/local/bin/rake
bundle=/usr/local/bin/bundle

root=/srv/www/socialdash_app
current_path="${root}/current"
shared_path="${root}/shared"
release_path="$root/releases"
name=$1

export PATH=/usr/local/bin:$PATH
export RAILS_ENV=production
# cd $release_path/$name

$bundle exec bundle install --path=/home/deploy/.bundler/socialdash_app --without=test development
${rake} db:migrate
touch tmp/restart.txt
    