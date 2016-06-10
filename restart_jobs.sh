#!/bin/bash

export PATH="/home/uberdash/.rvm/gems/ruby-2.2.1/bin:/home/uberdash/.rvm/gems/ruby-2.2.1@global/bin:/home/uberdash/.rvm/rubies/ruby-2.2.1/bin:/home/uberdash/.rvm/gems/ruby-2.2.1/bin:/home/uberdash/.rvm/gems/ruby-2.2.1@global/bin:/home/uberdash/.rvm/rubies/ruby-2.2.1/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/home/uberdash/.rvm/bin:/home/uberdash/.rvm/bin"
export GEM_HOME='/home/uberdash/.rvm/gems/ruby-2.2.1'
export GEM_PATH='/home/uberdash/.rvm/gems/ruby-2.2.1:/home/uberdash/.rvm/gems/ruby-2.2.1@global'
export MY_RUBY_HOME='/home/uberdash/.rvm/rubies/ruby-2.2.1'
export IRBRC='/home/uberdash/.rvm/rubies/ruby-2.2.1/.irbrc'
export RUBY_VERSION='ruby-2.2.1'
# source /home/uberdash/.rvm/scripts/rvm && bundle exec rails runner -e production  "Scheduler.restart_jobs" 

/bin/bash -l -c 'source /home/uberdash/.rvm/scripts/rvm; cd /home/uberdash/hub/current && bundle exec rails runner -e production  "Account.restart_jobs"'