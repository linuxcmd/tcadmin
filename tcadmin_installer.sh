#!/bin/bash

#Script to install tcadmin.
#Use this script only on a FRESH/NEW SERVER

#===================variables========================#
db_pass=`cat /dev/urandom| tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1`
tcdbpass=`cat /dev/urandom| tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1`
tchost=localhost
tcuser=tcadmin
tcdatabase=tcadmindb
#=====================================================#

install_dependencies () {
wget http://www.tcadmin.com/installer/mono-2.11.4-x86_64.rpm
yum -y install mono-2.11.4-x86_64.rpm --nogpgcheck
sleep 2
/opt/mono-2.11.4/bin/mozroots --import --sync --quiet
/opt/mono-2.11.4/bin/mono --aot -O=all /opt/mono-2.11.4/lib/mono/2.0/mscorlib.dll
for i in /opt/mono-2.11.4/lib/mono/gac/*/*/*.dll; do /opt/mono-2.11.4/bin/mono --aot -O=all $i; done
yum install glibc.i686 libstdc++.i686 -y
sleep 2
wget http://www.tcadmin.com/installer/msttcorefonts-2.0-1.noarch.rpm
yum -y install msttcorefonts-2.0-1.noarch.rpm --nogpgcheck
sleep 2
yum -y install libpcap schedutils lsof glibc.i686 libstdc++.i686
}


install_tcadmin () {
cd /usr/local/src
wget http://www.tcadmin.com/installer/tcadmin-2-bi.noarch.rpm;yum -y install tcadmin-2-bi.noarch.rpm --nogpgcheck
sleep 2
}


install_mysql () {
yum install mysql-server mysql -y
/etc/init.d/mysqld start
mysqladmin -u root password "$db_pass"
echo "[mysql]" > /root/.my.cnf
echo "user=root" >> /root/.my.cnf
echo "password=$db_pass" >> /root/.my.cnf
echo "Configuring MySQL Now."
mysql << EOF
    DELETE FROM mysql.user WHERE User='';
    DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
    DROP DATABASE test;
    DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
    flush privileges;
EOF
echo "Completed!!"
}

tcadmindb_setup () {
echo "creating database for tcadmin"
mysql << EOF
   create database $tcdatabase;
   grant all privileges on $tcdatabase.* to '$tcuser'@'$tchost' identified by '$tcdbpass';
   flush privileges;
EOF
echo "Completed!!"
sleep 2
echo "Installation completed, please see http://help.tcadmin.com/Installation for more info"
echo "Try accessing TCADMIN using IPADDRESS:8880 on any web browser"
echo "=========TCAdmin database details==========="
echo "Host=> $tchost"
echo "Database name=> $tcdatabase"
echo "User=> $tcuser"
echo "Password=> $tcdbpass"
echo "USE THIS DETAILS TO CONVERT SQLITE TO MYSQL"
echo "==========================================="
}

install_remote () {
install_dependencies
install_tcadmin
}

install_master () {
install_dependencies
install_tcadmin
install_mysql
tcadmindb_setup
}

if [[ $1 = "master" ]]; then
        clear
        install_master 2>&1 | tee /var/log/tcadmin_master_install.log
elif [[ $1 = "remote" ]]; then
        clear
        install_remote 2>&1 | tee /var/log/tcadmin_remote_install.log
else
        clear
        echo "Command usage : $0 remote/master"
        echo "To setup tcadmin master server type \"$0 master\" and vice versa"
fi
