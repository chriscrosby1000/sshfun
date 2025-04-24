#!/bin/bash


#This script will loop through the user.csv file and start an ssh instance 
#for each user.

tail -n +2 users.csv | while IFS=',' read -r net oct port user pass
do

 ./s.sh -n $net -o $oct -p $port -u $user -w $pass

done

