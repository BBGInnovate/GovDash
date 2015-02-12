#!/bin/bash

user=lliu
env=staging
user=oddev
env=production

cd /home/$user/socialdash/current
[[ -s "/home/$user/.rvm/scripts/rvm" ]] && . "/home/$user/.rvm/scripts/rvm"
RAILS_ENV=$env bin/delayed_job stop
