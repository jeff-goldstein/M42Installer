#!/bin/bash

# This is a full single node installer for Momo 4.2.28 Including complete API, WebUI and WebHooks
# Note that you must first install 4.2.14, then upgrade to 4.2.28
# Full instructions to build from scratch are included here
# To make this work, place this script along with downloaded bunldes for V4.2.12 and v4.2.28 in /var/tmp before executing this script
# https://support.messagesystems.com/package.php/momentum-bundle-4.2.1.56364.rhel6.x86_64.tar.gz
# https://support.messagesystems.com/package.php/momentum-bundle-4.2.28.58446.rhel6.x86_64.tar.gz

# Optionally preset values here
export FNAME='Development Server'
export MYFQDN='dev4.trymsys.net'
export USERNAME='Tom Mairs'
export EMAIL='tom.mairs@sparkpost.com'
export TZ='MST'

# paste your server CERT and KEY here before executing this script
# -OR- ensure that you update the files before trying to use the software.

CERT="-----BEGIN CERTIFICATE----- \
# Replace this first \
-----END CERTIFICATE-----"

KEY="-----BEGIN PRIVATE KEY-----  \
# Replace this first \
-----END PRIVATE KEY-----"





#####################################################
# DO NOT CHANGE ANYTHING BELOW THIS LINE
#####################################################

cd /var/tmp
# lynx https://support.messagesystems.com/docs
# Download .12 and .28 bundles here

clear
echo Installing Momo 4.2.28.FULL - PoC Singlenode FULL MTA Installer version
echo
echo  -Version 4-
echo
echo Please send the MAC below to licensing@messagesystems.com for a valid license
ifconfig |grep -i HWaddr
echo

echo "Press ENTER/RETURN to continue"
read R

echo Launch a CentOS 6.5 instance 
echo "(CentOS 6.5 (x86_64) - Release Media\) "
echo Select instance type m3.xlarge, \(recommended\) click NEXT
echo Select "Protect against accidental termination", click NEXT
echo Update the volume size to 200Mb
echo Click NEXT and add a tag so you can find your instance later
echo Select a security group - I use "SSH+SMTP+HTTP+API+METRICS"
echo click LAUNCH and select or create a key pair so you can log in for further configuration
echo 
echo Before going further, create a resolvable domain in DNS and ensure that is is resolvable.

echo open a shell and log in 
echo IE: ssh -i tmairs-oregon.pem ec2-user@ec2-54-190-177-235.us-west-2.compute.amazonaws.com

echo move this installer to that server and execute it there

# if running this manually, make sure you are sudo or root first
# sudo -s

#alter the following vars then paste most of the rest...
echo Send this MAC to licensing@messagesystems.com and ask for a key

ifconfig |grep -i HWaddr
echo

echo "If you have already done all of the above, press ENTER/RETURN to continue"
read R

if [ ${FNAME} = "" ]; then
  echo 'Enter the friendly name of this server (IE: \"my dev server\")'
  read FNAME
fi

if [ $MYFQDN = "" ]; then
  echo 'Enter the FQDN  (IE: \"myserver.home.net\") or press ENTER/RETURN for default'
  read MYFQDN
fi

if [ ${USERNAME}="" ];then
echo 'Enter the name of the system operator (IE: \"Bob Jones\")'
read USERNAME
fi

if [ $EMAIL = "" ];then
echo 'Enter the email address of the above system operator (IE: \"bob@here.com\")'
read EMAIL
fi

if [ $TZ = "" ];then
echo 'What timezone is the server in? (EST,CST,MST,PST)'
read TZ
fi

   if [ $TZ = "EDT" ]; then
      MYTZ="America/New_York"
   fi
   if [ $TZ = "CDT" ]; then
      MYTZ="America/Chicago"
   fi
   if [ $TZ = "MDT" ]; then
      MYTZ="America/Edmonton"
   fi
   if [ $TZ = "PDT" ]; then
      MYTZ="America/Los_Angeles"
   fi

   if [ $TZ = "EST" ]; then
      MYTZ="America/New_York"
   fi
   if [ $TZ = "CST" ]; then
      MYTZ="America/Chicago"
   fi
   if [ $TZ = "MST" ]; then
      MYTZ="America/Edmonton"
   fi
   if [ $TZ = "PST" ]; then
      MYTZ="America/Los_Angeles"
   fi
   if [ $MYTZ = "" ]; then
      echo "No TZ selected, using Pacific Time as default"
      MYTZ="America/Los_Angeles"
   fi

echo "PLEASE WAIT....."



 # Use $HOSTNAME instead
 # MYHOST=`hostname -f`
 if [ $MYFQDN="" ]; then
  MYFQDN=`hostname -f`
 fi 
  PUBLICIP=`curl -s checkip.dyndns.org|sed -e 's/.*Current IP Address: //' -e 's/<.*$//' `
    PRIVATEIP=`hostname -i`
  
echo
echo Using these settings:
echo Friendly Name = $FNAME
echo FQDN = $MYFQDN
echo USERNAME = $USERNAME
echo Contact EMAIL = $EMAIL
echo HOSTNAME = $HOSTNAME
echo Public IP = $PUBLICIP
echo Private IP = $PRIVATEIP
echo Time Zone = $MYTZ
echo

export DEFAULT=/opt/msys/ecelerity/etc/conf/default/
echo 'export DEFAULT=/opt/msys/ecelerity/etc/conf/default/' >> /etc/profile
 
echo "Applying environment changes..."
echo "..............................."

OUTPUT="$(df)"
DRIVE=`echo ${OUTPUT} |  awk '{print $8;}'`
MOUNT=`echo ${DRIVE} |  cut -f 3 -d "/"`
echo $DRIVE
echo $MOUNT

echo "
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [82:15000]
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT
-A INPUT -i eth0 -p tcp -m tcp --dport 25 -j ACCEPT
-A INPUT -i eth0 -p tcp -m tcp --dport 80 -j ACCEPT
-A INPUT -i eth0 -p tcp -m tcp --dport 81 -j ACCEPT
-A INPUT -i eth0 -p tcp -m tcp --dport 443 -j ACCEPT
-A INPUT -i eth0 -p tcp -m tcp --dport 587 -j ACCEPT
-A INPUT -j REJECT --reject-with icmp-host-prohibited
-A FORWARD -j REJECT --reject-with icmp-host-prohibited
COMMIT
" > /etc/sysconfig/iptables
service iptables restart
sed -i "s/HOSTNAME=\(.*\)/HOSTNAME=$HOSTNAME/" /etc/sysconfig/network
echo 'export TZ=$MYTZ' >> /etc/profile
export TZ=$MYTZ

echo "
$PRIVATEIP  $HOSTNAME
$PUBLICIP $MYFQDN" >> /etc/hosts

sudo echo "
vm.max_map_count = 768000
net.core.rmem_default = 32768
net.core.wmem_default = 32768
net.core.rmem_max = 262144
net.core.wmem_max = 262144
fs.file-max = 250000
net.ipv4.ip_local_port_range = 5000 63000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
kernel.shmmax = 68719476736
net.core.somaxconn = 1024
vm.nr_hugepages = 10
kernel.shmmni = 4096
" >> /etc/sysctl.conf

sudo /sbin/sysctl -p /etc/sysctl.conf

sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config  
/usr/sbin/setenforce 0


cd /var/tmp
chkconfig ntpd on 
/etc/init.d/ntpd start 
service postfix stop
/sbin/chkconfig postfix off

service qpidd stop
/sbin/chkconfig qpidd off

echo 
echo "Resizing the drive..." 
echo "..............................."
resize2fs $DRIVE

echo
echo "Updating the swap file..." 
echo "..............................."
sudo dd if=/dev/zero of=/swapfile bs=1024 count=2048k
sudo mkswap /swapfile
sudo swapon /swapfile
chown root:root /swapfile 
chmod 0600 /swapfile
echo "/swapfile               swap                    swap    defaults        0 0" >> /etc/fstab
mount -a


/sbin/blockdev --setra 2048 $DRIVE
echo deadline > /sys/block/$MOUNT/queue/scheduler
echo "/sbin/blockdev --setra 2048 $DRIVE" >>/etc/rc.local
echo "echo deadline > /sys/block/$MOUNT/queue/scheduler" >>/etc/rc.local
echo "export LANG=en_US.UTF-8" >> /etc/profile



echo
echo "Updating existing packages..."
echo "..............................."
yum clean headers
yum clean packages
yum clean metadata

yum -y groupinstall base
yum -y update

echo
echo "Adding required packages..."
echo "..............................."

yum -y install perl mcelog sysstat ntp gdb lsof.x86_64 wget yum-utils bind-utils telnet mlocate lynx unzip sudo
yum -y install make gcc curl cpan mysql*


# Adding specific version of Java
rpm -e `rpm -qa | grep java`
wget http://javadl.sun.com/webapps/download/AutoDL?BundleId=97799
mv AutoDL?BundleId=97799 jre-7-linux-x64.rpm
rpm -Uvh jre-7-linux-x64.rpm

alternatives --install /usr/bin/java java /usr/java/jre1.7.0_71/bin/java 3


cd /var/tmp
MOMOVER=`find -name 'momentum-bundle*.tar.gz'`
if [ ${MOMOVER} = "" ]; then
  echo "Install bundles not found. Download them first and then continue"
  echo "DOWNLOAD the 4.2.28 and .12 versions of Momentum"
  echo " or SCP the bundle to /var/tmp" 
  echo "Before continuing"
  echo "Press ENTER/RETURN to continue to LYNX or ^C to exit now."
  echo
  read R
  lynx https://support.messagesystems.com/docs
  echo "Press ENTER/RETURN to continue to LYNX or ^C to exit now."
  read R
fi


export MOMOVER1="momentum-bundle-4.2.1.56364.rhel6.x86_64.tar.gz"
export MOMOVER2="momentum-bundle-4.2.28.58446.rhel6.x86_64.tar.gz"
export MOMOREL1="momentum-4.2.1.56364"
export MOMOREL2="momentum-4.2.28.58446"


###########################################################################
# Put v.12 Install instructions here
###########################################################################

cd /var/tmp

echo 
echo Unpacking version $MOMOREL1 . Please wait....
echo ...
tar -zxf $MOMOVER1
cd $MOMOREL1/

echo "Installing from $MOMOREL1.  press ^C to exit or ENTER to continue"
read R


./setrepodir
pwd >/var/tmp/inst.dir


yum install -y --config momentum.repo --enablerepo momentum \
  msys-role-mta \
  msys-app-webhooks-cql \
  msys-app-webhooks-etl \
  msys-app-metrics-etl 

yum install -y --config momentum.repo --enablerepo momentum \
  msys-role-combined \
  msys-role-db \
  msys-ecelerity-config-server \
  msys-ecelerity-engagement-proxy \
  msys-app-adaptive-delivery-db \
  msys-app-adaptive-delivery-etl \
  msys-app-adaptive-delivery-api \
  msys-app-webhooks-batch-db

/opt/msys/ecelerity/bin/ec_lic -f

mkdir -p /opt/msys/etc
< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c8   > /opt/msys/etc/.svcpasswd
export SVCPASSWD=`cat /opt/msys/etc/.svcpasswd`
export ADMINPASS=admin

echo $HOSTNAME > /opt/msys/etc/.dbhost

cat <<EOF >/var/tmp/sedfqdns
s/yournode01.yourdomain.tld/$HOSTNAME/
EOF

cat <<EOF >/var/tmp/sedips
s/YOURIP01/127.0.0.1/
EOF

sed "s/yournode/yourvert/" </var/tmp/sedfqdns >/var/tmp/sedfqdns.vert

echo $HOSTNAME >/var/tmp/initialnode.txt

service msyspg start
sleep 2
cd /opt/msys/ecelerity/etc
../bin/init_schema --password $SVCPASSWD --admin-password $ADMINPASS

sed -i -e "s/UseCanonicalName DNS/ServerName $HOSTNAME/" ecconfigd.conf
sed -i -e "s/Include \"/#Include \"/" ecconfigd.conf

export CLUSTER="CAS-`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c8`"
echo $CLUSTER >/var/tmp/cass.cluster

export IPADDRESS=`host $HOSTNAME | cut -d' ' -f4`
export CASSNODES=$HOSTNAME
echo $IPADDRESS
echo $CASSNODES

/opt/msys/3rdParty/cassandra/bin/update_cass_yaml \
  --seeds="$CASSNODES" --listen $IPADDRESS --cluster-name=$CLUSTER \
  --rpc 0.0.0.0 --rpc_max_threads=200 \
  --thrift_framed_transport_size_in_mb=25 --force

service msys-cassandra start
sleep 30
service msys-cassandra status

export PATH=/opt/msys/3rdParty/bin:$PATH
cd /opt/msys/ecelerity/etc
../bin/cassandra_momo_setup.sh --singlenode $PWD |   tee -a /opt/msys/app/users-api/cql/cassandra_schema.log
cd /opt/msys/app/users-api/cql
cqlsh $IPADDRESS -f load_singlenode_keyspace.cql   2>&1 | tee -a /opt/msys/app/users-api/cql/cassandra_schema.log
cqlsh $IPADDRESS -k authentication   -f upgrades/V2015.01.20_00.00.00__create_customer_metadata.cql   2>&1 | tee -a /opt/msys/app/users-api/cql/cassandra_schema.log
cqlsh $IPADDRESS -k authentication   -f  upgrades/V2015.01.21_00.00.00__add_terms_of_use_column.cql   2>&1 | tee -a /opt/msys/app/users-api/cql/cassandra_schema.log
cqlsh $IPADDRESS -k authentication   -f upgrades/V2015.05.21_00.00.00__add_email_verified_column.cql   2>&1 | tee -a /opt/msys/app/users-api/cql/cassandra_schema.log
cd /opt/msys/app/webhooks-api/cql
cqlsh $IPADDRESS -f load_singlenode_keyspace.cql   2>&1 | tee -a /opt/msys/app/users-api/cql/cassandra_schema.log

cd /opt/msys/ecelerity/etc
mkdir -p /opt/msys/etc/installer/ecelerity.d
mkdir -p /opt/msys/etc/installer/ecconfigd.d

sed -i -e "s/UseCanonicalName DNS/ServerName $HOSTNAME/" ecconfigd.conf

echo
echo COPY the password below so you can paste it in the next prompt...
echo $SVCPASSWD
echo
read R

## THIS NEEDS TO BE DONE MANUALLY

/opt/msys/ecelerity/bin/create_ssl_cert ecconfigd $HOSTNAME /var/ecconfigd/apache
/opt/msys/3rdParty/apache/sbin/htdigest -c /var/ecconfigd/repo/svn-auth.htdigest  "ecconfigd repo" ecuser

echo "Complete the step above, press ENTER/RETURN to continue"
read R


echo
echo use "admin" in the next prompt...
echo

/opt/msys/3rdParty/apache/sbin/htdigest /var/ecconfigd/repo/svn-auth.htdigest "ecconfigd repo" admin 

echo "Complete the step above, press ENTER/RETURN to continue"
read R


service ecconfigd start

cd /opt/msys/ecelerity/etc
chmod g+ws .
/opt/msys/ecelerity/bin/eccfg bootstrap --singlenode  --username admin --password $ADMINPASS

cat sample-configs/default/msg_gen.conf | sed "s/your[cm]node/yournode/" | \
   sed -f /var/tmp/sedfqdns | grep -v "#UNCOMMENT.*yournode" | \
   sed "s/#UNCOMMENT-AS-NEEDED //" | grep -v "cluster_cfg *= *true" | \
   grep -v "node.*mta_id" | sed "s/host=.*port=/host=127.0.0.1;port=/" >conf/default/msg_gen.conf
   
sed -i "s/__EXTERNAL_DNS_HOSTNAME__/$MYFQDN/" conf/default/msg_gen.conf

sed -i -e 's/# include "msg_gen.conf"/include "msg_gen.conf"/'  conf/default/ecelerity.conf

../bin/eccfg commit -m 'Update and enable msg_gen config'   --add-all --username admin --password $ADMINPASS


cd /opt/msys/ecelerity/etc
cat << EOT > conf/default/ecdb.conf
Datasource "ecdb" {
  uri = ( "pgsql:host=$HOSTNAME;dbname=ecelerity;user=ecuser;password=$SVCPASSWD" )
}
EOT
sed -i -e 's|/opt/msys/etc/installer/eccmgr.d/||' \
  conf/default/eccluster.conf
sed -i -e 's|/opt/msys/etc/installer/ecelerity.d/|ecdb.conf|' \
  conf/default/ecelerity.conf
../bin/eccfg commit -m 'Add ecdb config' --username admin \
   --add-all --password $ADMINPASS


export THIRDPARTY=/opt/msys/3rdParty
export RABBITMQCTL="$THIRDPARTY/sbin/rabbitmqctl"
export RABBITMQADMIN="$THIRDPARTY/sbin/rabbitmqadmin"
service msys-rabbitmq start
$RABBITMQADMIN declare exchange name=momentum_metrics type=topic
$RABBITMQADMIN declare queue name=msg_events
$RABBITMQADMIN declare binding source=momentum_metrics \
  destination=msg_events \
  routing_key=msys.*
$RABBITMQCTL add_user rabbitmq "p1-Vk0lXy"
$RABBITMQCTL set_user_tags rabbitmq administrator
$RABBITMQCTL set_permissions -p '/' rabbitmq '.*' '.*' '.*'
$RABBITMQCTL delete_user guest

cd /opt/msys/3rdParty/nginx/conf.d

cat /opt/msys/ecelerity/etc/sample-configs/nginx/click_proxy_upstream.conf | \
  sed "s/your.node/yournode/" | sed -f /var/tmp/sedfqdns | grep -v "#UNCOMMENT-AS-NEEDED.*yournode" | \
  sed "s/#UNCOMMENT-AS-NEEDED//" | sed 's/:81/:2081/' >click_proxy_upstream.conf
cat /opt/msys/ecelerity/etc/sample-configs/nginx/momo_upstream.conf | \
  sed "s/your.node/yournode/" | sed -f /var/tmp/sedfqdns | grep -v "#UNCOMMENT-AS-NEEDED.*yournode" | \
  sed "s/#UNCOMMENT-AS-NEEDED//" >momo_upstream.conf
cat /opt/msys/ecelerity/etc/sample-configs/nginx/webui_upstream.conf | \
  sed "s/your.node/yournode/" | sed -f /var/tmp/sedfqdns | grep -v "#UNCOMMENT-AS-NEEDED.*yournode" | \
  sed "s/#UNCOMMENT-AS-NEEDED//" >webui_upstream.conf
cat /opt/msys/ecelerity/etc/sample-configs/nginx/api_metrics_upstream.conf | \
  sed "s/your.node/yournode/" | sed -f /var/tmp/sedfqdns | grep -v "#UNCOMMENT-AS-NEEDED.*yournode" | \
  sed "s/#UNCOMMENT-AS-NEEDED//" >api_metrics_upstream.conf
cat /opt/msys/ecelerity/etc/sample-configs/nginx/api_webhooks_upstream.conf | \
  sed "s/your.node/yournode/" | sed -f /var/tmp/sedfqdns | grep -v "#UNCOMMENT-AS-NEEDED.*yournode" | \
  sed "s/#UNCOMMENT-AS-NEEDED//" >api_webhooks_upstream.conf
cat /opt/msys/ecelerity/etc/sample-configs/nginx/api_users_upstream.conf | \
  sed "s/your.node/yournode/" | sed -f /var/tmp/sedfqdns | grep -v "#UNCOMMENT-AS-NEEDED.*yournode" | \
  sed "s/#UNCOMMENT-AS-NEEDED//" >api_users_upstream.conf
cat /opt/msys/ecelerity/etc/sample-configs/nginx/api_adaptive_delivery_upstream.conf | \
  sed "s/your.node/yournode/" | sed -f /var/tmp/sedfqdns | grep -v "#UNCOMMENT-AS-NEEDED.*yournode" | \
  sed "s/#UNCOMMENT-AS-NEEDED//" >api_adaptive_delivery_upstream.conf
cp /dev/null api_webhooks.conf
service msys-nginx configtest


export PATH=/opt/msys/3rdParty/bin:$PATH
export APPDIR=/opt/msys/app

export VERT=`sed </var/tmp/sedfqdns.vert -e 's/^.*yourvert...yourdomain.tld.//;s/\///;s/^.*/"&"/' | \
    tr "\012" "," | sed 's/,$//' | sed 's/,/, /'`
echo $VERT

for etl_dir in $APPDIR/*-etl/config $APPDIR/metrics-api/config $APPDIR/metrics-api/cron/config $APPDIR/adaptive-delivery-api/config \
$APPDIR/adaptive-delivery-api/cron/config; do
  jq ".vertica.hosts=[$VERT]" -a -M -n > $etl_dir/production.json
done

export CASS=`sed </var/tmp/sedfqdns -e 's/^.*yournode...yourdomain.tld.//;s/\///;s/^.*/"&"/' | tr "\012" "," | sed 's/,$//' | sed 's/,/, /'`
echo $CASS

for webhook_dir in $APPDIR/webhooks-*/config ; do
  jq ".cassandra.contactPoints=[$CASS] | .vertica.hosts=[$VERT] | .api.uri=\"http://127.0.0.1:2084/api/v1/webhooks\"" \
    -a -M -n > $webhook_dir/production.json
done
  
for cron_dir in $APPDIR/webhooks-*/cron/config ; do
  jq ".cassandra.contactPoints=[$CASS] | .vertica.hosts=[$VERT]" \
    -a -M -n > $cron_dir/production.json
done

jq ".cassandra.contactPoints=[$CASS]" -a -M -n > $APPDIR/users-api/config/production.json

jq '.auth.enabled=true | .auth.apiHost=false | .auth.apiPort=false | .adaptiveDelivery.enabled=true' -a -M $APPDIR/webui/scripts/config/default.json > $APPDIR/webui/scripts/config/production.json



# Dealing with Vertica Now...
groupadd verticadba
useradd vertica_dba -m -g verticadba -d /var/db/vertica
chown vertica_dba:verticadba /var/db/vertica

cd `cat /var/tmp/inst.dir`
export VERT_CONF='/opt/vertica/config'
export RPMFILE=`/bin/ls $PWD/packages/msys-vertica* | fgrep -v client`

cat << EOF > ./silent_install
accept_eula = True
data_dir = /var/db/vertica
direct_only = True
failure_threshold = FAIL
license_file = $VERT_CONF/licensing/Message_Systems_vertica.license.key
rpm_file_name = $RPMFILE
spread_subnet = default
vertica_dba_group = verticadba
vertica_dba_user = vertica_dba
vertica_dba_user_dir = /var/db/vertica
vertica_dba_user_password_disabled = True
EOF


export SERVERS=`sed </var/tmp/sedips -e 's/^.*YOURIP...//;s/\///' | tr "\012" "," | sed 's/,$//'`
echo $SERVERS
echo TZ="America/Los_Angeles"

export VERT_BIN='/opt/vertica/bin'
export VERT_SBIN='/opt/vertica/sbin'
$VERT_SBIN/install_vertica -z ./silent_install -s $SERVERS 2>&1 | tee vertica_install.log

# remove unused or conflicting services from all vertica nodes
/sbin/chkconfig vertica_agent off
rm -f /etc/init.d/vertica_agent
/sbin/chkconfig verticad off
rm -f /etc/init.d/verticad

chmod 777 /tmp/2025 

su -l vertica_dba
$VERT_BIN/admintools --tool create_db --hosts=$SERVERS --database=msys 2>&1 | tee -a vertica_install.log

export APPDIR=/opt/msys/app
cd $APPDIR/db/
chmod 777 scripts/*.sh

export APPDIR=/opt/msys/app
cd $APPDIR/db/
export TZ="America/Los_Angeles"

/opt/msys/app/db/flyway migrate -locations=filesystem:/opt/msys/app/db/schema -jarDirs=drivers -placeholders.schema=momo

# Setup storage locations:
./scripts/metrics_storage_location.sh
./scripts/webhooks_storage_location.sh

# Run updates to the tuple mover: 
/opt/vertica/bin/vsql -U vertica_dba -f /opt/msys/app/db/scripts/V2015.07.09_14.35.00__update_tuple_mover.sql

# Trigger move out
/opt/vertica/bin/vsql -U vertica_dba -c "select do_tm_task('moveout');"

/opt/vertica/bin/vsql -U vertica_dba -c "select * from wos_container_storage;"

/opt/vertica/bin/vsql -U vertica_dba -f /opt/msys/app/db/scripts/V2015.07.09_14.45.00__update_wos.sql

echo "set search_path='momo';\\i /opt/msys/app/db/data-migrations/V2015.01.27_14.30.00__repartition_msg_events.sql" | /opt/vertica/bin/vsql -U vertica_dba

echo "set search_path='momo';\\i /opt/msys/app/db/projections/singlenode_sql/latest_metrics_projection.sql" | /opt/vertica/bin/vsql -U vertica_dba
echo "set search_path='momo';\\i /opt/msys/app/db/projections/singlenode_sql/latest_webhooks_projection.sql" | /opt/vertica/bin/vsql -U vertica_dba
echo "set search_path='momo';\\i /opt/msys/app/db/projections/singlenode_sql/latest_ad_projections.sql" | /opt/vertica/bin/vsql -U vertica_dba

/opt/vertica/bin/admintools -t set_restart_policy -d msys --policy always
exit



# Now start all the services:

service msys-app-metrics-etl start
service msys-app-adaptive-delivery-etl start
service msys-app-webhooks-batch start
service msys-app-webhooks-transmitter start
service msys-riak start
service ecelerity start
service msys-nginx start
service msys-app-metrics-api start
service msys-app-adaptive-delivery-api start
service msys-app-users-api start
service msys-app-webhooks-api start


curl -XPOST -H "X-MSYS-CUSTOMER: 1" -H "Content-Type: application/json" -d \
   '{ "username" : "admin", "password": "changemenow", "access" : "admin", "lastName" : "myLastName", "firstName" : "myFirstName", "email" : "myEmailAddress@example.com" }' \
   http://localhost:2085/api/v1/users

sed -i 's/, sending_disabled//' /opt/msys/app/users-api/cql/upgrades/V2015.01.20_02.00.00__populate_customer_metadata.cql


/opt/msys/3rdParty/bin/cqlsh -k authentication -f /opt/msys/app/users-api/cql/upgrades/V2014.06.11_00.00.00__add_oauth_clients.cql 2>&1 >> cassandra_schema.log
/opt/msys/3rdParty/bin/cqlsh -k authentication -f /opt/msys/app/users-api/cql/upgrades/V2014.12.21_00.00.00__create_user_emails.cql 2>&1 >> cassandra_schema.log
/opt/msys/3rdParty/bin/cqlsh -k authentication -f /opt/msys/app/users-api/cql/upgrades/V2014.12.22_00.00.00__populate_email_users.cql 2>&1 >> cassandra_schema.log
/opt/msys/3rdParty/bin/cqlsh -k authentication -f /opt/msys/app/users-api/cql/upgrades/V2015.01.20_01.00.00__extract_customers.cql 2>&1 >> cassandra_schema.log
/opt/msys/3rdParty/bin/cqlsh -k authentication -f /opt/msys/app/users-api/cql/upgrades/V2015.01.20_02.00.00__populate_customer_metadata.cql 2>&1 >> cassandra_schema.log
/opt/msys/3rdParty/bin/cqlsh -k authentication -f /opt/msys/app/users-api/cql/upgrades/V2015.04.09_00.00.00__create_unsuccessful_logins.cql 2>&1 >> cassandra_schema.log
/opt/msys/3rdParty/bin/cqlsh -k authentication -f /opt/msys/app/users-api/cql/upgrades/V2015.04.10_00.00.00__two_factor.cql 2>&1 >> cassandra_schema.log
/opt/msys/3rdParty/bin/cqlsh -k authentication -f /opt/msys/app/users-api/cql/upgrades/V2015.04.28_00.00.00__add_is_sso_column.cql 2>&1 >> cassandra_schema.log
/opt/msys/3rdParty/bin/cqlsh -k authentication -f /opt/msys/app/users-api/cql/upgrades/V2015.04.28_00.00.00__add_tou_last_updated.cql 2>&1 >> cassandra_schema.log
/opt/msys/3rdParty/bin/cqlsh -k authentication -f /opt/msys/app/users-api/cql/upgrades/V2015.05.21_00.00.00__create_email_verification_tokens.cql 2>&1 >> cassandra_schema.log
/opt/msys/3rdParty/bin/cqlsh -k authentication -f /opt/msys/app/users-api/cql/upgrades/V2015.06.16_00.00.00__add_saml_column.cql 2>&1 >> cassandra_schema.log
/opt/msys/3rdParty/bin/cqlsh -k authentication -f /opt/msys/app/users-api/cql/upgrades/V2015.06.17_00.00.00__add_valid_ip_column.cql 2>&1 >> cassandra_schema.log
/opt/msys/3rdParty/bin/cqlsh -k authentication -f /opt/msys/app/users-api/cql/upgrades/V2015.06.22_00.00.00__add_last_login_column.cql 2>&1 >> cassandra_schema.log



 

sed -i 's/server {/server { \
  listen 443 ssl; \
  ssl_certificate     \/etc\/pki\/tls\/certs\/server.crt; \
  ssl_certificate_key \/etc\/pki\/tls\/certs\/server.key; \
  ssl_protocols  TLSv1 TLSv1.1 TLSv1.2; \
  ssl_ciphers "AES128+EECDH:AES128+EDH"; \
  ssl_prefer_server_ciphers on; \
  ssl_session_cache shared:SSL:10m; \
  add_header Strict-Transport-Security "max-age=63072000; includeSubDomains"; \
  add_header X-Frame-Options DENY; \
  add_header X-Content-Type-Options nosniff; \
/' /opt/msys/3rdParty/nginx/conf.d/web_proxy.conf

echo "$CERT" > /etc/pki/tls/certs/server.crt
echo "$KEY" > /etc/pki/tls/certs/server.key
chmod 644 /etc/pki/tls/certs/server.*
service msys-nginx configtest
service msys-nginx restart

# To fix the ecconfig stack trace problem
sed -i 's/use strict;/$ENV{GIMLI_WATCHDOG_INTERVAL} = 300;\nuse strict;/' /etc/init.d/ecconfigd
service ecconfigd restart




###########################################################################
# Put v.28 Upgrade instructions here
###########################################################################

cd /var/tmp

echo 
echo Unpacking version $MOMOREL2 . Please wait....
echo ...
tar -zxf $MOMOVER2
cd $MOMOREL2/

./setrepodir
pwd >/var/tmp/inst.dir

service eccmgr stop
service ecconfigd stop
service msys-riak stop
service msys-cassandra stop
service msc_server stop
service msys-rabbitmq stop
service msys-vertica stop
service msys-app-metrics-etl stop
service msys-app-adaptive-delivery-etl stop
service msys-app-webhooks-batch stop
service msys-app-webhooks-transmitter stop
service ecelerity stop
service msys-nginx stop
service msys-app-metrics-api stop
service msys-app-adaptive-delivery-api stop
service msys-app-users-api stop
service msys-app-webhooks-api stop


yum remove -y --disablerepo=* --config momentum.repo --enablerepo momentum \
  msys-ecelerity-generic-engagement_tracker \
  msys-cpan-Test-Tester \
  msys-cpan-Test-use-ok 

yum upgrade -y --disablerepo=* --config momentum.repo --enablerepo momentum 
 
 
 
#####################################################################
# IMPORTANT... This *WAS* the end of script#1 but I figured out how to automate 
# the above yum shell so it is now all one script.  You're welcome.
#####################################################################





###########################################################
# This is part 2 of the 4.2.28 FULL installer.
# End=sure these environment variables are the same as 
# in script 1
###########################################################

#export FNAME='Development Server'
#export MYFQDN='dev4.trymsys.net'
#export USERNAME='Tom Mairs'
#export EMAIL='tom.mairs@sparkpost.com'
#export TZ='MST'
#export DEFAULT=/opt/msys/ecelerity/etc/conf/default/
#export MOMOVER1="momentum-bundle-4.2.1.56364.rhel6.x86_64.tar.gz"
#export MOMOVER2="momentum-bundle-4.2.28.58446.rhel6.x86_64.tar.gz"
#export MOMOREL1="momentum-4.2.1.56364"
#export MOMOREL2="momentum-4.2.28.58446"


 sed -i 's/cassandra_client {/cassandra_native_client {/' /opt/msys/ecelerity/etc/conf/default/msg_gen.conf  
 sed -i 's/uri = (/contact_points = (/' /opt/msys/ecelerity/etc/conf/default/msg_gen.conf  
 sed -i 's/"name=(.*)9160"/<FQDN>/' /opt/msys/ecelerity/etc/conf/default/msg_gen.conf 


 /opt/msys/ecelerity/bin/cassandra_momo_setup.sh --multinode /opt/msys/ecelerity/etc

service eccmgr start
service ecconfigd start
service msys-riak start
service msys-cassandra start
service msc_server start
service msys-rabbitmq start
service msys-vertica start
#service msys-app-metrics-etl stop
#service msys-app-adaptive-delivery-etl stop
#service msys-app-webhooks-batch stop
#service msys-app-webhooks-transmitter stop
service ecelerity start
service msys-nginx start
service msys-app-metrics-api start
service msys-app-adaptive-delivery-api start
service msys-app-users-api start
service msys-app-webhooks-api start




########################################################
# END of Momentum install and upgrade
########################################################



###########################################################
# These are custom for the SETEAM install
###########################################################

# To label the server with a descriptive and helpful MOTD
# Edit as needed for this install

echo "








##############################################

Welcome to the $FNAME server 
[ https://$MYFQDN ]

Hosting Momentum $MOMOREL2 FULL DEPLOY

 - for any questions, please contact
$USERNAME <$EMAIL>

##############################################
" > /etc/motd

echo "
echo \"version\" |/opt/msys/ecelerity/bin/ec_console
echo " > /etc/motd.sh

echo "sh /etc/motd.sh" >> /etc/profile



#######################################################################################
#
# WARNING 
#
# This following section is to give users server access
# You may want to edit this section before running the script
#
#######################################################################################
# to give seteam users sudo access to the server
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config   
echo "seteam        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
service sshd restart

useradd seteam
passwd seteam
#######################################################################################
#######################################################################################


#######################################################################################
#
# WARNING 
#
# This following section generates and alters system configuration
# You may want to edit this section before running the script
#
#######################################################################################


mkdir $DEFAULT/lua
mkdir $DEFAULT/conf.d


#################################
# FBL Config
#################################
echo "
Enable_FBL_Header_Insertion = enabled

fbl {
  Auto_Log = true # default is \"false\"
  Log_Path = \"jlog:///var/log/ecelerity/fbllog.jlog=>master\"
  Addresses = ( \"^.*@fbl.$MYFQDN\" ) # default is unset
  Header_Name = \"X-MSFBL\" # this is the default
#  User_String = \"%{vctx_mess:my_context_variable}\" # default is unset
  Message_Disposition = \"pass\" # default is blackhole, also allowed to set to \"pass\"
#  Condition = \"can_relay\" # default is unset, should be name of a vctx entry
}
" > $DEFAULT/conf.d/fbl.conf


#################################
# DKIM Config
#################################
echo "
opendkim_sign = \"enabled\"

opendkim \"opendkim1\" {
  header_canon = \"relaxed\"
  body_canon = \"relaxed\"
  headerlist = (\"from\", \"to\", \"message-id\", \"date\", \"subject\", \"Content-Type\")
  digest = \"rsa-sha256\"
  key = \"/opt/msys/ecelerity/etc/conf/default/dk/%{d}/%{s}.key\"
  dkim_domain \"$MYFQDN\" {
    selector = \"s1024\"
  }

}
" > $DEFAULT/conf.d/dkim.conf



#################################
# ADAPTIVE Config
#################################
echo "
adaptive_enabled = true
adaptive_notification_interval = 5
adaptive_adjustment_interval = 10

adaptive  {
  suspend_sweep_interval = 5
  operational_log_level = \"debug\"
  jlog_file = \"jlog:///var/log/ecelerity/adaptive.rt=>ad_stats\"
  enable_jlog = true
}

alerting {}

scriptlet \"scriptlet\" {
  # Add the Lua adaptive script
  script \"adaptive\" {
    source = \"msys.adaptive\"
  }
}

inbound_audit {
  monitors = (\"300,6\")
}" > $DEFAULT/conf.d/adaptive.conf



#################################
# BINDING Config
#################################
echo "
binding_group general {

  binding \"generic\" {
  }
  binding \"marketing\" {
  }
  binding \"news\" {
  }
  binding \"trans\" {
  }
  binding \"msys\" {
  }
}
" > $DEFAULT/conf.d/bindings.conf


#################################
# General ecelerity config
#################################
sed -i 's/Bounce_Domains /#Bounce_Domains /' $DEFAULT/ecelerity.conf
sed -i 's/Bounce_Behavior /#Bounce_Behavior /' $DEFAULT/ecelerity.conf
sed -i 's/Generate_bounces /#Generate_bounces /' $DEFAULT/ecelerity.conf
echo "include \"conf.d\"" >> $DEFAULT/ecelerity.conf

echo "
#
# Additional ecelerity mods to add.  Remember to INCLUDE this file in ecelerity.conf
#

Bounce_Domains = (\"*.$MYFQDN\")
Bounce_Behavior = blackhole
Generate_bounces = false

scriptlet \"scriptlet\" {
  script \"policy\" {
    source = \"$DEFAULT/lua/policy.lua\"
  }
}

eventloop \"pool\" {
concurrency = 4
}

delivery_pool = \"pool\"
maintainer_pool = \"pool\"


#smtpapi{}

ESMTP_Listener{
  Listen \":587\" {
    Enable = true
    TLS_Verify_Mode = \"require\"
    TLS_Certificate = \"/etc/pki/tls/certs/server.crt\"
    TLS_Key = \"/etc/pki/tls/certs/server.key\"
    TLS_Client_CA = \"/etc/pki/tls/certs/server.crt\"
    TLS_Ciphers = \"DEFAULT\"
    AuthLoginParameters = [
       uri = \"file:///opt/msys/ecelerity/etc/unsafe_passwd\"
    ]
    SMTP_Extensions = ( \"ENHANCEDSTATUSCODES\" \"STARTTLS\" \"AUTH LOGIN\" )
#    tracking_domain = \"$MYFQDN:81\"
  }
}

#tls_macros {}


" > $DEFAULT/conf.d/ecelerity_mods.conf



#################################
# Mobile Config
#################################
echo "
smpp_logger \"smpp_logger\"
{
  logfile = \"/var/log/ecelerity/smpplog.ec\"
  logmode = 0644
  log_reception_format = \"%t@R@%m@%s@%d@%q@%bg@%b@%ip@%l\"
  log_permfail_format = \"%t@P@%m@%s@%d@%q@%bg@%b@%ip@%e\"
  log_delivery_format = \"%t@D@%m@%s@%d@%q@%bg@%b@%ip@%l@%rm\"
  log_tempfail = false
  log_status = false
}

#Datasource \"ram\" {
#  uri = ( \"pgsql:host=localhost;dbname=ecelerity;user=ecuser;password=123456\")
#  no_cache = \"true\"
#}

smpp {
   debug_level=debug
}


#domain mblox.sms.agg {
#  SMPP_SMSC_Server = \"smpp.mt.us.mblox.com\"
#  SMPP_SMSC_Port = \"3210\"
#  SMPP_SMSC_System_ID = \"<redacted>\"
#  SMPP_SMSC_Password = \"<redacted>\"
#  SMPP_ESME_Address = \"<redacted>\"
#  SMPP_Default_Email_Address = \"<redacted>\"
#  SMPP_Registered_Delivery = (SMSC_Delivery)
#  SMPP_Max_Sms_Subject_Size = \"0\"
#  SMPP_ESME_Service_Type = \"32538\"
#  SMPP_SMS_Data_Coding = \"ascii\"
#  SMPP_Inactivity_Timer = 600
#  SMPP_Enquire_Link_Timer = 90
#  SMPP_Response_Timer = 60
#}
" > $DEFAULT/conf.d/mobile.conf


#################################
# Lua Policy
#################################
echo "
require(\"msys.core\");
require(\"msys.db\");
require(\"msys.pcre\");
require(\"msys.dumper\");
require(\"msys.extended.message\");
require(\"msys.extended.message_routing\");
require(\"msys.extended.ac\");

local mod = {};

--[[ Modify these as necessesary for your demo ]]--
local sinkdomain = \"54.244.3.35\"
local safedomains = { \"mblox.sms.agg\", \"validator.messagesystems.com\", \"messagesystems.com\", \"sparkpost.com\" }

--[[ each rcpt_to function ]]--
function mod:validate_data_spool_each_rcpt (msg, accept, vctx)
--  print (\"Using data_spool_each_rcpt\");
  return msys.core.VALIDATE_CONT;
end 


--[[ each MSG_GEN rcpt_to function ]]--
function mod:msg_gen_data_spool(msg)
--  print (\"Using msg_gen_data_spool\");
  return msys.core.VALIDATE_CONT;
end


--[[ Set Binding function ]]--
function mod:validate_set_binding(msg)
  local domain_str = msys.core.string_new();
  local localpart_str = msys.core.string_new();
  msg:get_envelope2(msys.core.EC_MSG_ENV_TO, localpart_str, domain_str);
  local mydomain = tostring(domain_str);
  local mylocalpart = tostring(localpart_str);
  local validdomain = \"false\"
  local bindingname = msg:header(\"X-Binding\")

  if bindingname[1] then 
    msg:context_set(msys.core.VCTX_MESS, \"mo_binding\", bindingname[1])
  end


-- Test to see if the TO domain is in the safe list
  for i,v in ipairs(safedomains) do
    if v == mydomain then
    --  print (\"Routing to a valid domain: \" .. mydomain);
      validdomain = \"true\"
      break
   end
  end

  if validdomain == \"false\" then

  --  print (\"Sending this to sink: \" .. sinkdomain .. \" / \" .. mydomain);
    msg:routing_domain(sinkdomain);
  end
    if ( ( bindingname[1] ~= \"\" ) and (bindingname[1] ~= nil ) )  then
      local err = msg:binding(bindingname[1]);
    else 
      local err = msg:binding(\"generic\");
    end


-- print(msg:context_get(msys.core.ECMESS_CTX_MESS, 'mo_campaign_id'));

  return msys.core.VALIDATE_CONT;
end;

msys.registerModule(\"policy\", mod);
" > $DEFAULT/lua/policy.lua


#######################################
# Commit and restart
#######################################
chown ecuser.ecuser $DEFAULT/* -R
service ecelerity restart

echo 
echo 
echo "Installation complete!"
echo 
echo 
cat /etc/motd
sh /etc/motd.sh



