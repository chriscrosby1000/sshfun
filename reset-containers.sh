#!/bin/bash
#
#this script in intended to be called by cron every hour with the following crontabe entry 
#   0 * * * * /root/sshfun/reset-containers.sh
#
#
name="sshfun"

while getopts "n:h" opt; do
  case $opt in
    n) name="$OPTARG";;
    h) echo "Usage: $0 [-n network_name]"
       exit 0
       ;;
  esac
done


# Stop can remove the shared containers 
docker stop $(docker ps --filter="Name=$name" -qa)
docker container rm  $(docker ps --filter="Name=$name" -qa)

# restart the containers default values are
# network = 'sshfun'
# port = 2222
# third_octet = 22
# user = student 
# password = 'Goodluck!'
#
# If you want to overide these defaults then use the scripts arguments
# s.sh -h for more info
#  
#/root/sshfun/s.sh

# remove any unused images 
# docker rmi $(docker images -qa) 2> /dev/null
