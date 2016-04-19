##################
#Read Config file
##################

source /etc/keystone/admin-openrc.sh

##################
# Horizon : Install and configure
##################
apt-get install openstack-dashboard -y

horizon_config='/etc/openstack-dashboard/local_settings.py'

sed -i '/OPENSTACK_HOST = /s/^/#/' $horizon_config
sed -i '/OPENSTACK_HOST = /a OPENSTACK_HOST = "controller"' $horizon_config

sed -i '/ALLOWED_HOSTS = /s/^/#/' $horizon_config
echo "ALLOWED_HOSTS = ['*',]" >> $horizon_config

sed -i '/OPENSTACK_KEYSTONE_DEFAULT_ROLE/s/^/#/' $horizon_config
sed -i '/OPENSTACK_KEYSTONE_DEFAULT_ROLE/a OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"' $horizon_config

sed -i '/TIME_ZONE/s/^/#/' $horizon_config
sed -i '/TIME_ZONE/a TIME_ZONE = "EST"' $horizon_config

service apache2 reload
