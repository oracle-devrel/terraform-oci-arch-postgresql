#!/bin/bash

echo '#################################################'
echo 'Starting PostgreSQL Master setup for HotStandby2.'
echo '#################################################'

export pg_version='${pg_version}'
export add_iscsi_volume='${add_iscsi_volume}'

# Setting firewall rules
echo '--> Updating firewall rules with hotstandby2 IP (${pg_hotstandby_ip}) on master host...'
sudo -u root bash -c "firewall-cmd --permanent --zone=trusted --add-source=${pg_hotstandby_ip}/32"
sudo -u root bash -c "firewall-cmd --permanent --zone=trusted --add-port=5432/tcp"
sudo -u root bash -c "firewall-cmd --reload"
echo '-[100%]-> Firewall updated with hotstandby2 IP (${pg_hotstandby_ip}) on master host.' 

if [[ $add_iscsi_volume == "true" ]]; then 
	echo '--> Updating the content of pg_hba.conf file to include standby host for replication...'
	sudo -u root bash -c "echo 'host replication ${pg_replicat_username} ${pg_hotstandby_ip}/32 md5' | sudo tee -a /data/pgsql/pg_hba.conf" 
	sudo -u root bash -c "echo 'host all all ${pg_hotstandby_ip}/32 md5' | sudo tee -a /data/pgsql/pg_hba.conf" 
	sudo -u root bash -c "chown postgres /data/pgsql/pg_hba.conf" 
    echo '-[100%]-> File pg_hba.conf updated with standby host data for replication.' 	
else
	echo '--> Updating the content of pg_hba.conf file to include standby host for replication...'
	sudo -u root bash -c "echo 'host replication ${pg_replicat_username} ${pg_hotstandby_ip}/32 md5' | sudo tee -a /var/lib/pgsql/${pg_version}/data/pg_hba.conf" 
	sudo -u root bash -c "echo 'host all all ${pg_hotstandby_ip}/32 md5' | sudo tee -a /var/lib/pgsql/${pg_version}/data/pg_hba.conf" 
	sudo -u root bash -c "chown postgres /var/lib/pgsql/${pg_version}/data/pg_hba.conf" 
    echo '-[100%]-> File pg_hba.conf updated with standby host data for replication.' 	
fi

echo '--> Restarting PostgreSQL systemctl service...'
sudo systemctl stop postgresql-${pg_version}
sudo systemctl start postgresql-${pg_version}
sudo systemctl status postgresql-${pg_version} --no-pager
echo '-[100%]-> PostgreSQL service restarted.'

echo '#################################################'
echo 'PostgreSQL Master setup for HotStandby2 finished.'
echo '#################################################'