#Install MariaDB 
sudo apt-get install mariadb-server python-mysqldb

#Install the Ubuntu Cloud archive keyring and repository
apt-get install ubuntu-cloud-keyring
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu" \
  "trusty-updates/kilo main" > /etc/apt/sources.list.d/cloudarchive-kilo.list

#Install MySqlDB and Python MySQL library
sudo apt-get install mariadb-server python-mysqldb

echo -e "[mysqld]\nbind-address = 10.0.0.11\ndefault-storage-engine = innodb\ninnodb_file_per_table\
\ncollation-server = utf8_general_ci\ninit-connect = 'SET NAMES utf8'\ncharacter-set-server = utf8 " > /etc/mysql/conf.d/mysqld_openstack.cnf

#Restart MySql Service
service mysql restart

#Install message queue service
apt-get install rabbitmq-server

#Configure message queue service
rabbitmqctl add_user openstack itdepends123
rabbitmqctl set_permissions openstack ".*" ".*" ".*"
-----------------------------------------------------
#Configure identity service
mysql -u root -p

#Create keystone database
CREATE DATABASE keystone;

#Grant proper access to database
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'10.42.0.11' \
  IDENTIFIED BY 'itdepends123';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' \
  IDENTIFIED BY 'itdepends123';

#Exit database
exit

#Generate random number for initial configuration
openssl rand -hex 10
------------------------------------------------------------
#Install and Configure Identity Service Components
# Diable Keystone to startautomatically from starting
echo "manual" > /etc/init/keystone.override
#Install  keystone python dependencies
apt-get install keystone python-openstackclient apache2 \
libapache2-mod-wsgi memcached python-memcache

#Configure the keystone.conf
###token=$(openssl rand -hex 10)
echo "[DEFAULT]\nadmin_token =$(openssl rand -hex 10)\n\n\
[database]\nconnection = mysql://keystone:itdepends123@controller/keystone\
\n[memcache]\nservers = localhost:11211\n[token]\nprovider = keystone.token.providers.uuid.Provider\
\ndriver = keystone.token.persistence.backends.memcache.Token\n
[revoke]\ndriver = keystone.contrib.revoke.backends.sql.Revoke\n
[DEFAULT]\nverbose = True" >/etc/keystone/keystone.conf

#Populate the identity service database
su -s /bin/sh -c "keystone-manage db_sync" keystone

#To configure the Apache HTTP server
apt-get install apache2
echo "ServerName controller" >> /etc/apache2/apache2.conf
service apache2 restart

#Delete SQL DB server  that keystone uses by default
rm -f /var/lib/keystone/keystone.d
