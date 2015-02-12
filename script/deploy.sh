#!/usr/bin/env bash
if test $# -eq 0
then
  printf "Usage for setup remote host: %s -s [-p] \n" $(basename $0) >&2
  printf " -e option for prod or dev enviroment\n"
  printf " -u option for user\n"
  printf " -i option for ssh key path\n"
  printf "Usage for deploy to remote host: %s [-env] [-b branch]\n" $(basename $0) >&2
  exit 2
fi

# staging host
#DEV=54.227.248.152
#production host
#PROD=54.83.61.132

#defaults
application='socialdash'
enviroment=dev
user=lliu
keyfile=~/.ssh/LLiu.pem
app_user=lliu
host=54.227.248.152

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
  host=54.83.61.132
  app_user=oddev
fi

echo "user: $user, key : $keyfile"
echo "deploy to $enviroment ($host)"
echo "version $version"

# ssh -i ~/.ec2/BBGInstance.pem -t 50.19.63.102 -l ubuntu "sudo su; ls"

root=/home/$app_user/$application
shared=$root/shared
name=`date '+%Y%m%d%H%M%S'`
dest=$root/shared/releases/$name

tarfile=${name}_${application}.tar 
branchcode=`git ls-remote -t https://liwenl:jx1951@bitbucket.org/bbginnovate-ondemand/socialdash $branch`
 
## branchcode=`git ls-remote git@localhost:/Users/git/hub.git $branch`
## branchcode=`git ls-remote git@github.com:BBGInnovate/rIvr.git $branch`
branchcode=(`echo $branchcode | tr ' ' ' '`)
branch=${branchcode[0]}

mkdir -p /tmp
cd /tmp
rm -rf socialdash

git clone https://liwenl:jx1951@bitbucket.org/bbginnovate-ondemand/socialdash socialdash
## git clone  git@localhost:/Users/git/hub.git
## git clone git@github.com:BBGInnovate/rIvr.git

cd socialdash
git checkout -fb $branch
tar cvf $tarfile --exclude '*.tar' --exclude 'tmp' --exclude '*.git' *

scp -i ${keyfile} $tarfile ${user}@${host}:/tmp/.
ssh -i ${keyfile} -t ${host} -l ${user} \
   "mkdir -p $dest; \
   mkdir -p $shared/config; \
   mkdir -p $shared/tmp;  \
   mkdir -p $shared/log; \
   cd $dest; \
   tar xvf /tmp/$tarfile ; \
   rm /tmp/$tarfile ; \
   cd $root; \
   rm -f current ; \
   source /home/$app_user/.rvm/scripts/rvm; \
   ln -s $dest current; \
   rm -f current/config/database.yml; \
   echo $version >> $shared/versions.txt; \
   ln -s $shared/config/database.yml current/config/database.yml; \
   ln -s $shared/log current/log; \
   rm -rf  tmp/cache/assets; \
   rm -rf public/assets; \
   rake assets:precompile; \
   ln -s $shared/tmp current/tmp; \
   cd current; \
   rake db:migrate RAILS_ENV=production; \
   source /home/$app_user/.rvm/scripts/rvm; \
   touch tmp/restart.txt;"


