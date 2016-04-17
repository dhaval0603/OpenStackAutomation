##################
#Read Config file
##################

config_file='../config/controller.conf'
controller_ip=$(grep -Po 'controller_ip=\K[^ ]+' $config_file)
compute_ip=$(grep -Po 'compute_ip=\K[^ ]+' $config_file)
mysql_password=$(grep -Po 'mysql_password=\K[^ ]+' $config_file)
glance_password=$(grep -Po 'glance_password=\K[^ ]+' $config_file)

##################
#Pre Reqs for Glance
##################

mysql --user="root" --password="$mysql_password" --e "CREATE DATABASE glance;"
mysql --user="root" --password="$mysql_password" --e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '$glance_password';"
mysql --user="root" --password="$mysql_password" --e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'$controller_ip' IDENTIFIED BY '$glance_password';"

source /etc/keystone/admin-openrc.sh

openstack user create --password $glance_password glance
openstack role add --project service --user glance admin
openstack service create --name glance --description "OpenStack Image service" image

openstack endpoint create --publicurl http://controller:9292 --internalurl http://controller:9292 --adminurl http://controller:9292 --region RegionOne image

##################
# Glance : Install and configure
##################
apt-get install glance python-glanceclient -y

#Glance API config
glance_api_config='/etc/glance/glance-api.conf'
cp $glance_api_config $glance_api_config.bak

echo "[database]
connection = mysql://glance:$glance_password@controller/glance
backend = sqlalchemy
sqlite_db = /var/lib/glance/glance.sqlite

[keystone_authtoken]
auth_uri = http://controller:5000
auth_url = http://controller:35357
auth_plugin = password
project_domain_id = default
user_domain_id = default
project_name = service
username = glance
password = $glance_password
 
[paste_deploy]
flavor = keystone

[glance_store]
default_store = file
filesystem_store_datadir = /var/lib/glance/images/

[DEFAULT]
bind_host = 0.0.0.0
bind_port = 9292
registry_host = 0.0.0.0
registry_port = 9191
registry_client_protocol = http
log_file = /var/log/glance/api.log
backlog = 4096
notification_driver = noop
verbose = True
delayed_delete = False
scrub_time = 43200
scrubber_datadir = /var/lib/glance/scrubber
image_cache_dir = /var/lib/glance/image-cache/

# Configuration options if sending notifications via rabbitmq (Defaults)
rabbit_host = localhost
rabbit_port = 5672
rabbit_use_ssl = false
rabbit_userid = guest
rabbit_password = guest
rabbit_virtual_host = /
rabbit_notification_exchange = glance
rabbit_notification_topic = notifications
rabbit_durable_queues = False

# Configuration options if sending notifications via Qpid (Defaults)
qpid_notification_exchange = glance
qpid_notification_topic = notifications
qpid_hostname = localhost
qpid_port = 5672
qpid_username =
qpid_password =
qpid_sasl_mechanisms =
qpid_reconnect_timeout = 0
qpid_reconnect_limit = 0
qpid_reconnect_interval_min = 0
qpid_reconnect_interval_max = 0
qpid_reconnect_interval = 0
qpid_heartbeat = 5
qpid_protocol = tcp
qpid_tcp_nodelay = True" > $glance_api_config

#Glance Registry config
glance_registry_config='/etc/glance/glance-registry.conf'
cp $glance_registry_config $glance_registry_config.bak

echo "[database]
connection = mysql://glance:$glance_password@controller/glance
sqlite_db = /var/lib/glance/glance.sqlite
backend = sqlalchemy

[keystone_authtoken]
auth_uri = http://controller:5000
auth_url = http://controller:35357
auth_plugin = password
project_domain_id = default
user_domain_id = default
project_name = service
username = glance
password = $glance_password
 
[paste_deploy]
flavor = keystone

[DEFAULT]
notification_driver = noop
verbose = True
bind_host = 0.0.0.0
bind_port = 9191
log_file = /var/log/glance/registry.log
backlog = 4096
api_limit_max = 1000
limit_param_default = 25
# Configuration options if sending notifications via rabbitmq (Defaults)
rabbit_host = localhost
rabbit_port = 5672
rabbit_use_ssl = false
rabbit_userid = guest
rabbit_password = guest
rabbit_virtual_host = /
rabbit_notification_exchange = glance
rabbit_notification_topic = notifications
rabbit_durable_queues = False

# Configuration options if sending notifications via Qpid (Defaults)
qpid_notification_exchange = glance
qpid_notification_topic = notifications
qpid_hostname = localhost
qpid_port = 5672
qpid_username =
qpid_password =
qpid_sasl_mechanisms =
qpid_reconnect_timeout = 0
qpid_reconnect_limit = 0
qpid_reconnect_interval_min = 0
qpid_reconnect_interval_max = 0
qpid_reconnect_interval = 0
qpid_heartbeat = 5
qpid_protocol = tcp
qpid_tcp_nodelay = True" > $glance_registry_config


/bin/sh -c "glance-manage db_sync" glance

service glance-registry restart
service glance-api restart

rm -f /var/lib/glance/glance.sqlite


