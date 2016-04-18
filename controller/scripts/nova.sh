##################
#Read Config file
##################

config_file='config/controller.conf'
controller_ip=$(grep -Po 'controller_ip=\K[^ ]+' $config_file)
compute_ip=$(grep -Po 'compute_ip=\K[^ ]+' $config_file)
mysql_password=$(grep -Po 'mysql_password=\K[^ ]+' $config_file)
nova_password=$(grep -Po 'nova_password=\K[^ ]+' $config_file)

##################
#Pre Reqs for Nova
##################

mysql --user="root" --password="$mysql_password" --e "CREATE DATABASE nova;"
mysql --user="root" --password="$mysql_password" --e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '$nova_password';"
mysql --user="root" --password="$mysql_password" --e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'$controller_ip' IDENTIFIED BY '$nova_password';"

source /etc/keystone/admin-openrc.sh

openstack user create --password $nova_password nova
openstack role add --project service --user nova admin
openstack service create --name nova --description "OpenStack Compute" compute

openstack endpoint create --publicurl http://controller:8774/v2/%\(tenant_id\)s --internalurl http://controller:8774/v2/%\(tenant_id\)s --adminurl http://controller:8774/v2/%\(tenant_id\)s --region RegionOne compute

##################
# Nova : Install and configure
##################
apt-get install nova-api nova-cert nova-conductor nova-consoleauth nova-novncproxy nova-scheduler python-novaclient

#Glance API config
nova_config='/etc/nova/nova.conf'
cp $nova_config $nova_config.bak

echo "[database]
connection = mysql://nova:$nova_password@controller/nova

[DEFAULT]
rpc_backend = rabbit
rabbit_host = controller
rabbit_userid = openstack
rabbit_password = $rabbit_password
auth_strategy = keystone
dhcpbridge_flagfile=/etc/nova/nova.conf
dhcpbridge=/usr/bin/nova-dhcpbridge
logdir=/var/log/nova
state_path=/var/lib/nova
lock_path=/var/lock/nova
force_dhcp_release=True
libvirt_use_virtio_for_bridges=True
verbose=True
ec2_private_dns_show_ip=True
api_paste_config=/etc/nova/api-paste.ini
enabled_apis=ec2,osapi_compute,metadata
my_ip = $controller_ip
vncserver_listen = $controller_ip
vncserver_proxyclient_address = $controller_ip

[glance]
host = controller

[oslo_concurrency]
lock_path = /var/lib/nova/tmp

[keystone_authtoken]
auth_uri = http://controller:5000
auth_url = http://controller:35357
auth_plugin = password
project_domain_id = default
user_domain_id = default
project_name = service
username = nova
password = $nova_password " > $nova_config


/bin/sh -c "nova-manage db_sync" nova

service nova-api restart
service nova-cert restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart

rm -f /var/lib/nova/nova.sqlite
