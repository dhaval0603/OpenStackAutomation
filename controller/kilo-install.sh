#!/bin/bash
##################
#Root check
##################

rootuser=` whoami|grep root|wc -l `

if [ $rootuser != "1" ] 
then
    echo ""
    echo "Not running as root. Exiting..."
    echo ""
    exit 0
fi

./scripts/environment.sh
./scripts/keystone.sh
./scripts/glance.sh
./scripts/nova.sh
./scripts/horizon.sh
