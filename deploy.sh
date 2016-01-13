#!/bin/bash

while getopts 'pgb:' OPTION
  do
    case $OPTION in
    p) env=production;;
    b) branch="$OPTARG"
      ;;
    [?]) printf "Usage: %s: [-p] [-b branch] args\n" $(basename $0) >&2
      exit 2
      ;;
    esac
done
shift $(($OPTIND - 1))
echo "version $branch"

root=/home/uberdash/socialdash_app
current_path="${root}/current"
shared_path="${root}/shared"
release_path="$root/releases"
git_app=GovDash
repos=https://LiwenL@github.com/BBGInnovate/${git_app}.git
name=`date '+%Y%m%d%H%M%S'`
# name=20160108124817
ruby=/home/uberdash/.rvm/rubies/ruby-2.2.1/bin/ruby
rake=/home/uberdash/.rvm/rubies/ruby-2.2.1/bin/rake
bundle=/home/uberdash/.rvm/gems/ruby-2.2.1/bin/bundle

aliases=( govdash-1 govdash-2 )
array=( 0 )

configs="config/database.yml config/email.yml config/facebook.yml config/rabbit.yml config/twitter.yml \
  config/youtube.yml config/s3.yml config/sitecatalyst.yml \
  log"
secret_token="config/secret_token.rb"

for i in ${array[@]}
do
  alias=${aliases[$i]}
  echo "deploy to $alias $release_path"
  echo "clone $repos $name"
  ssh -t $alias "cd $release_path; \
    sudo git clone $repos $name; \
    cd $name ; \
    sudo mkdir -p tmp; \
    echo checkout -fb $branch ; \
    sudo git checkout -fb $branch ; \
    
    for j in $configs; do sudo ln -fs ${shared_path}/\$j \$j ;done; \
    sudo ln -fs ${shared_path}/$secret_token config/initializers/secret_token.rb; \
    sudo ln -fs ${shared_path}/system public/system; \
    sudo chown -R uberdash:www-data ${release_path}/$name; \
    sudo rm $current_path; \
    sudo ln -fs ${release_path}/$name $current_path; \
    sudo su - uberdash -c 'cd $release_path/$name; ./bundle_install.sh';
   "
done
# sudo su - deploy -c 'cd /srv/www/socialdash_app/releases/20160107123115 && /usr/local/bin/bundle install --path /home/deploy/.bundler/socialdash_app --without=test development'
