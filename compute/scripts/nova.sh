#!/bin/bash
##################
#Read Config file
##################

config_file='config/compute.conf'
controller_ip=$(grep -Po 'controller_ip=\K[^ ]+' $config_file)
compute_ip=$(grep -Po 'compute_ip=\K[^ ]+' $config_file)
nova_password=$(grep -Po 'nova_password=\K[^ ]+' $config_file)
local_interface_name=$(grep -Po 'local_interface_name=\K[^ ]+' $config_file)
public_interface_name=$(grep -Po 'public_interface_name=\K[^ ]+' $config_file)
rabbit_pass=$(grep -Po 'rabbit_password=\K[^ ]+' $config_file)

##################
#Nova : Install
##################

apt-get install nova-compute sysfsutils -y
apt-get install nova-network nova-api-metadata -y

nova_config='/etc/nova/nova.conf'
cp $nova_config $nova_config.bak

echo "[DEFAULT]
rpc_backend = rabbit
rabbit_host = controller
rabbit_userid = openstack
rabbit_password = $rabbit_pass
auth_strategy = keystone
my_ip = $compute_ip
vnc_enabled = True
vncserver_listen = 0.0.0.0
vncserver_proxyclient_address = $compute_ip
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
network_api_class = nova.network.api.API
security_group_api = nova
firewall_driver = nova.virt.libvirt.firewall.IptablesFirewallDriver
network_manager = nova.network.manager.FlatDHCPManager
network_size = 254
allow_same_net_traffic = False
multi_host = True
send_arp_for_ha = True
share_dhcp_address = True
force_dhcp_release = True
flat_network_bridge = br100
flat_interface = $local_interface_name
public_interface = $public_interface_name

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
service nova-network restart
service nova-api-metadata restart
rm -f /var/lib/nova/nova.sqlite
