#!/bin/bash
##################
#Read Config file
##################

config_file='config/compute.conf'
controller_ip=$(grep -Po 'controller_ip=\K[^ ]+' $config_file)
compute_ip=$(grep -Po 'compute_ip=\K[^ ]+' $config_file)
nova_password=$(grep -Po 'nova_password=\K[^ ]+' $config_file)

##################
#Nova : Install
##################

apt-get install nova-compute sysfsutils -y

nova_config='/etc/nova/nova.conf'
cp $nova_config $nova_config.bak

echo "[DEFAULT]
rpc_backend = rabbit
rabbit_host = controller
rabbit_userid = openstack
rabbit_password = RABBIT_PASS
auth_strategy = keystone
my_ip = MANAGEMENT_INTERFACE_IP_ADDRESS
vnc_enabled = True
vncserver_listen = 0.0.0.0
vncserver_proxyclient_address = MANAGEMENT_INTERFACE_IP_ADDRESS
novncproxy_base_url = http://controller:6080/vnc_auto.html
verbose = True
dhcpbridge_flagfile=/etc/nova/nova.conf
dhcpbridge=/usr/bin/nova-dhcpbridge
logdir=/var/log/nova
state_path=/var/lib/nova
lock_path=/var/lock/nova
force_dhcp_release=True
libvirt_use_virtio_for_bridges=True
ec2_private_dns_show_ip=True
api_paste_config=/etc/nova/api-paste.ini
enabled_apis=ec2,osapi_compute,metadata

[keystone_authtoken]
auth_uri = http://controller:5000
auth_url = http://controller:35357
auth_plugin = password
project_domain_id = default
user_domain_id = default
project_name = service
username = nova
password = $nova_pass

[glance]
host = controller

[oslo_concurrency]
lock_path = /var/lib/nova/tmp" > $nova_config


##################
#Nova : Hardware Acceleration check
##################
nova_compute_config='/etc/nova/nova-compute.conf'

if [ `egrep -c '(vmx|svm)' /proc/cpuinfo` == "0" ];
then
    sed -i '/virt_type/s/^/#/' $nova_compute_config
    echo "virt_type = qemu" >> $nova_compute_config
fi

service nova-compute restart
rm -f /var/lib/nova/nova.sqlite
