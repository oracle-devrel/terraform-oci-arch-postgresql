#!/bin/bash

echo '#################################################'
echo 'Starting PostgreSQL Master setup for HotStandby2.'
echo '#################################################'

export pg_version='${pg_version}'
export add_iscsi_volume='${add_iscsi_volume}'

# Setting firewall rules
sudo -u root bash -c "firewall-cmd --permanent --zone=trusted --add-source=${pg_hotstandby_ip}/32"
sudo -u root bash -c "firewall-cmd --permanent --zone=trusted --add-port=5432/tcp"
sudo -u root bash -c "firewall-cmd --reload"

if [[ $add_iscsi_volume == "true" ]]; then 
	# Update the content of pg_hba to include standby host for replication
	sudo -u root bash -c "echo 'host replication ${pg_replicat_username} ${pg_hotstandby_ip}/32 md5' | sudo tee -a /data/pgsql/pg_hba.conf" 
	sudo -u root bash -c "echo 'host all all ${pg_hotstandby_ip}/32 md5' | sudo tee -a /data/pgsql/pg_hba.conf" 
	sudo -u root bash -c "chown postgres /data/pgsql/pg_hba.conf" 
else
	# Update the content of pg_hba to include standby host for replication
	sudo -u root bash -c "echo 'host replication ${pg_replicat_username} ${pg_hotstandby_ip}/32 md5' | sudo tee -a /var/lib/pgsql/${pg_version}/data/pg_hba.conf" 
	sudo -u root bash -c "echo 'host all all ${pg_hotstandby_ip}/32 md5' | sudo tee -a /var/lib/pgsql/${pg_version}/data/pg_hba.conf" 
	sudo -u root bash -c "chown postgres /var/lib/pgsql/${pg_version}/data/pg_hba.conf" 
fi

# Restart of PostrgreSQL service
sudo systemctl stop postgresql-${pg_version}
sudo systemctl start postgresql-${pg_version}
sudo systemctl status postgresql-${pg_version}

echo '#################################################'
echo 'PostgreSQL Master setup for HotStandby2 finished.'
echo '#################################################'