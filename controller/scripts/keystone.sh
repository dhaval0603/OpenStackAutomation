##################
#Read Config file
##################

config_file='config/controller.conf'
controller_ip=$(grep -Po 'controller_ip=\K[^ ]+' $config_file)
compute_ip=$(grep -Po 'compute_ip=\K[^ ]+' $config_file)
mysql_password=$(grep -Po 'mysql_password=\K[^ ]+' $config_file)
keystone_password=$(grep -Po 'keystone_password=\K[^ ]+' $config_file)
admin_token= openssl rand -hex 10

##################
#Pre Reqs for Keystone
##################

mysql --user="root" --password="$mysql_password" --e "CREATE DATABASE keystone;"
mysql --user="root" --password="$mysql_password" --e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$keystone_password';"
mysql --user="root" --password="$mysql_password" --e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'$controller_ip' IDENTIFIED BY '$keystone_password';"


##################
#Install and Configure Keystone
##################

echo "manual" > /etc/init/keystone.override

apt-get install keystone python-openstackclient apache2 libapache2-mod-wsgi memcached python-memcache -y

keystone_config='/etc/keystone/keystone.conf'
cp $keystone_config $keystone_config.bak

echo "[DEFAULT] 
admin_token = $admin_token
verbose = True
log_dir = /var/log/keystone
 
[database]
connection = mysql://keystone:$keystone_password@controller/keystone
 
[memcache]
servers = localhost:11211
 
[token]
provider = keystone.token.providers.uuid.Provider
driver = keystone.token.persistence.backends.memcache.Token
 
[revoke]
driver = keystone.contrib.revoke.backends.sql.Revoke
 " >> $keystone_config

/bin/sh -c "keystone-manage db_sync" keystone

##################
#Install and Configure Apache
##################
echo "ServerName controller" >> /etc/apache2/apache2.conf

apache_keystone_config='/etc/apache2/sites-available/wsgi-keystone.conf'
touch $apache_keystone_config

echo 'Listen 5000
Listen 35357

<VirtualHost *:5000>
    WSGIDaemonProcess keystone-public processes=5 threads=1 user=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-public
    WSGIScriptAlias / /var/www/cgi-bin/keystone/main
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    <IfVersion >= 2.4>
      ErrorLogFormat "%{cu}t %M"
    </IfVersion>
    LogLevel info
    ErrorLog /var/log/apache2/keystone-error.log
    CustomLog /var/log/apache2/keystone-access.log combined
</VirtualHost>

<VirtualHost *:35357>
    WSGIDaemonProcess keystone-admin processes=5 threads=1 user=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-admin
    WSGIScriptAlias / /var/www/cgi-bin/keystone/admin
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    <IfVersion >= 2.4>
      ErrorLogFormat "%{cu}t %M"
    </IfVersion>
    LogLevel info
    ErrorLog /var/log/apache2/keystone-error.log
    CustomLog /var/log/apache2/keystone-access.log combined
</VirtualHost> ' >> $apache_keystone_config

ln -s /etc/apache2/sites-available/wsgi-keystone.conf /etc/apache2/sites-enabled

mkdir -p /var/www/cgi-bin/keystone

curl http://git.openstack.org/cgit/openstack/keystone/plain/httpd/keystone.py?h=stable/kilo | tee /var/www/cgi-bin/keystone/main /var/www/cgi-bin/keystone/admin

chown -R keystone:keystone /var/www/cgi-bin/keystone

chmod 755 /var/www/cgi-bin/keystone/*

service apache2 restart

rm -f /var/lib/keystone/keystone.db
