#!/bin/bash

echo '#####################################'
echo 'Starting PostgreSQL Install Binaries.'
echo '#####################################'

echo '--> Install PostgreSQL Repo...'
if [[ $(uname -r | sed 's/^.*\(el[0-9]\+\).*$/\1/') == "el8" ]]
  then 
    if [[ $(uname -m | sed 's/^.*\(el[0-9]\+\).*$/\1/') == "aarch64" ]]
    then
      sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-aarch64/pgdg-redhat-repo-latest.noarch.rpm
      echo '-[100%]-> Install PostgreSQL Repo (aarch64/OL8) installed.' 
    else
      sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
      echo '-[100%]-> Install PostgreSQL Repo (x86_64/OL8) installed.'
    fi  
fi
if [[ $(uname -r | sed 's/^.*\(el[0-9]\+\).*$/\1/') == "el7" ]]
  then 
    if [[ $(uname -m | sed 's/^.*\(el[0-9]\+\).*$/\1/') == "aarch64" ]]
    then
      sudo yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-aarch64/pgdg-redhat-repo-latest.noarch.rpm
      echo '-[100%]-> Install PostgreSQL Repo (aarch64/OL7) installed.' 
    else
      sudo yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
      echo '-[100%]-> Install PostgreSQL Repo (x86_64/OL7) installed.'
    fi  
fi

echo '--> Install PostgreSQL Server...'
if [[ $(uname -r | sed 's/^.*\(el[0-9]\+\).*$/\1/') == "el7" ]]
then 
    sudo yum install -y postgresql${pg_version_no_dot}-server
fi
if [[ $(uname -r | sed 's/^.*\(el[0-9]\+\).*$/\1/') == "el8" ]]
then 
    sudo dnf -qy module disable postgresql
    sudo dnf install -y postgresql${pg_version_no_dot}-server
fi
echo '-[100%]-> Install PostgreSQL Server (postgresql${pg_version_no_dot}-server) installed.'

echo '--> Install PostgreSQL pg_basebackup utility...'
if [[ $(uname -r | sed 's/^.*\(el[0-9]\+\).*$/\1/') == "el7" ]]
then 
   sudo yum-config-manager --enable ol7_developer
   sudo yum-config-manager --enable ol7_developer_EPEL
   sudo yum install -y llvm5.0-devel
   sudo yum install -y postgresql${pg_version_no_dot}-devel
   echo '-[100%]-> Install PostgreSQL pg_utility (postgresql${pg_version_no_dot}-devel OL7) installed.'
fi 
if [[ $(uname -r | sed 's/^.*\(el[0-9]\+\).*$/\1/') == "el8" ]]
then 
   sudo yum-config-manager --enable ol8_developer
   sudo yum-config-manager --enable ol8_developer_EPEL
   sudo yum install -y llvm5.0-devel
   sudo yum install -y postgresql${pg_version_no_dot}-devel
   echo '-[100%]-> Install PostgreSQL pg_utility (postgresql${pg_version_no_dot}-devel OL8) installed.'
fi 

# Setting firewall rules
echo '--> Setting firewall rules...'
export pg_whitelisted_ip='${pg_whitelisted_ip}'
if [[ $pg_whitelisted_ip != "" ]]; then 
   sudo -u root bash -c "firewall-cmd --permanent --zone=trusted --add-source=${pg_whitelisted_ip}/32"
   echo '-[50%]-> Whitelisted IP ${pg_whitelisted_ip} added to firewall rules.'
fi
sudo -u root bash -c "firewall-cmd --permanent --zone=trusted --add-port=5432/tcp"
sudo -u root bash -c "firewall-cmd --reload"
echo '-[100%]-> Port 5432 added to firewall rules and firewall reloaded.'

echo '#####################################'
echo 'PostgreSQL Install Binaries finished.'
echo '#####################################'
