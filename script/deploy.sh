#!/usr/bin/env bash

# This script requires SSH to the socialdash_app host without password
# on Mac:
# ssh-keygen
# vi id_rsa.pub
# copy content in id_rsa.pub to deploy@${host}:/home/deploy/.ssh/authorized_keys
# chmod 400 authorized_keys
# ssh deploy@${host}   # without password
# usage:
# script/deploy.sh -e prod -b prod/1.0.0.7

if test $# -eq 0
then
  printf "Usage for setup remote host: %s -s [-p] \n" $(basename $0) >&2
  printf " -e option for prod or dev enviroment\n"
  printf " -u option for user\n"
  printf " -i option for ssh key path\n"
  printf "Usage for deploy to remote host: %s [-env] [-b branch]\n" $(basename $0) >&2
  exit 2
fi

#defaults
application='socialdash_app'
user=ubuntu
keyfile=/Users/lliu/.ssh/oddev.pem
app_user=deploy
hosts=(54.221.43.111)
git_auth=LiwenL:Changsha15\!

# script/deploy.sh -e prod -b prod/1.0.0.7
while getopts 'e:u:i:gb:' OPTION
  do
    case $OPTION in
    e) enviroment="$OPTARG"
    ;;
    u) user="$OPTARG"
    ;;
    i) keyfile="$OPTARG"
    ;;
    b) branch="$OPTARG"
      ;;
    [?]) printf "Usage: %s: [-e] [-b branch] args\n" $(basename $0) >&2
      exit 2
      ;;
    esac
done
shift $(($OPTIND - 1))
version=$branch

#set the host 
if [ "$enviroment" == "prod" ]; then
  hosts=(54.242.85.238 54.160.167.102)
fi

echo "user: $user, key : $keyfile"
echo "deploy to $enviroment ($hosts)"
echo "version $branch"

root=/srv/www/$application
shared=$root/shared
name=`date '+%Y%m%d%H%M%S'`
dest=$root/releases/$name

# branchcode=`git ls-remote -t https://liwenl:jx1951@bitbucket.org/bbginnovate-ondemand/socialdash $branch`
branchcode=`git ls-remote -t https://${git_auth}@github.com/BBGInnovate/GovDash.git $branch`
branchcode=(`echo $branchcode | tr ' ' ' '`)
# branch=${branchcode[0]}

mkdir -p /tmp
cd /tmp
rm -rf $application

git_auth=LiwenL:Changsha15\!
git clone https://${git_auth}@github.com/BBGInnovate/GovDash.git
cd GovDash
git checkout -fb $branch
tarfile=${name}_${application}.tar
tar cvf $tarfile --exclude '*.tar' --exclude 'log' --exclude 'tmp' --exclude '*.git' .

function deploy {
  host=$1
  scp $tarfile ${app_user}@${host}:/tmp/.
  ssh  -t ${host} -l ${app_user} \
    "mkdir -p $dest; \
     mkdir -p $shared/config; \
     mkdir -p $shared/tmp;  \
     mkdir -p $shared/log; \
     cd $dest; echo '   In folder ' $dest; \
     tar xf /tmp/$tarfile ; \
     cd $root; echo '   Root folder ' $root; \
     rm -f current ; \
     ln -s $dest current; \
     rm -f current/config/*.yml; \
     echo $version >> $shared/versions.txt; \
     ln -s $shared/config/database.yml current/config/database.yml; \
     ln -s $shared/config/email.yml current/config/email.yml; \
     ln -s $shared/config/facebook.yml current/config/facebook.yml; \
     ln -s $shared/config/rabbit.yml current/config/rabbit.yml; \
     ln -s $shared/config/s3.yml current/config/s3.yml; \
     ln -s $shared/config/secret_token.rb  current/config/secret_token.rb; \
     ln -s $shared/config/sitecatalyst.yml current/config/sitecatalyst.yml; \
     ln -s $shared/config/twitter.yml current/config/twitter.yml; \
     ln -s $shared/config/youtube.yml current/config/youtube.yml; \
     ln -s $shared/log current/log; \
     rm -rf  tmp/cache/assets; \
     rm -rf public/assets; \
     rake assets:precompile; \
     cd current; \
     rake db:migrate RAILS_ENV=production; \
     /usr/local/bin/bundle install --path /home/deploy/.bundler/socialdash_app --without=test development; \
     mkdir tmp; \
     touch tmp/restart.txt; "
}
for i in "${hosts[@]}"
do
#	 deploy $i
  ;
done
