
##################
#Read Config file
##################

config_file='config/controller.conf'
controller_ip=$(grep -Po 'controller_ip=\K[^ ]+' $config_file)
compute_ip=$(grep -Po 'compute_ip=\K[^ ]+' $config_file)
mysql_password=$(grep -Po 'mysql_password=\K[^ ]+' $config_file)
rabbit_password=$(grep -Po 'rabbit_password=\K[^ ]+' $config_file)

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

service ntp restart

##################
#Open Stack repo
##################

apt-get install ubuntu-cloud-keyring -y
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu" \
  "trusty-updates/kilo main" > /etc/apt/sources.list.d/cloudarchive-kilo.list

apt-get update && apt-get dist-upgrade -y

##################
#SQL Server
##################

apt-get install -y debconf-utils
export DEBIAN_FRONTEND="noninteractive"

echo "mysql-server mysql-server/root_password password $mysql_password
mysql-server mysql-server/root_password_again password $mysql_password" > /tmp/debconf.txt

debconf-set-selections /tmp/debconf.txt

apt-get install mariadb-server python-mysqldb -y

mysql_conf='/etc/mysql/conf.d/mysqld_openstack.cnf'
touch $mysql_conf
echo "[mysqld] " > $mysql_conf
echo "bind-address = $controller_ip" >> $mysql_conf
echo "default-storage-engine = innodb" >> $mysql_conf
echo "innodb_file_per_table" >> $mysql_conf
echo "collation-server = utf8_general_ci" >> $mysql_conf
echo "init-connect = 'SET NAMES utf8'" >> $mysql_conf
echo "character-set-server = utf8" >> $mysql_conf

service mysql restart

mysql --user="root" --password="$mysql_password" --e "DELETE FROM mysql.user WHERE User='';"
mysql --user="root" --password="$mysql_password" --e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql --user="root" --password="$mysql_password" --e "DROP DATABASE IF EXISTS test;"
mysql --user="root" --password="$mysql_password" --e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
mysql --user="root" --password="$mysql_password" --e "FLUSH PRIVILEGES;"

##################
#Message Queue
##################

apt-get install rabbitmq-server -y
rabbitmqctl add_user openstack $rabbit_password
rabbitmqctl set_permissions openstack ".*" ".*" ".*"


