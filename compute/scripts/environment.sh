#!/bin/bash
##################
#Read Config file
##################

config_file='config/compute.conf'
controller_ip=$(grep -Po 'controller_ip=\K[^ ]+' $config_file)
compute_ip=$(grep -Po 'compute_ip=\K[^ ]+' $config_file)

##################
#etc/hosts file creation
##################

hostsCtrl=`cat /etc/hosts|grep controller|wc -l`
hostsCompute=`cat /etc/hosts|grep compute1|wc -l`

if [ $hostsCtrl != "1" ] 
then
    echo "$controller_ip	controller" >> /etc/hosts
fi

if [ $hostsCompute != "1" ] 
then
    echo "$compute_ip	compute1" >> /etc/hosts
fi


##################
#NTP Install
##################

apt-get update
apt-get install ntp -y

cp /etc/ntp.conf /etc/ntp.conf.bak
sed -i 's/server 0.ubuntu.pool.ntp.org/server controller iburst/g' /etc/ntp.conf
sed -i '/server 1.ubuntu.pool.ntp.org/d' /etc/ntp.conf
sed -i '/server 2.ubuntu.pool.ntp.org/d' /etc/ntp.conf
sed -i '/server 3.ubuntu.pool.ntp.org/d' /etc/ntp.conf
rm /var/lib/ntp/ntp.conf


service ntp restart

##################
#Open Stack repo
##################

apt-get install ubuntu-cloud-keyring -y
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu" \
  "trusty-updates/kilo main" > /etc/apt/sources.list.d/cloudarchive-kilo.list

apt-get update && apt-get dist-upgrade -y

