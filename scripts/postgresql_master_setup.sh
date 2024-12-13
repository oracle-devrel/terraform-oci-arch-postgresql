#!/bin/bash

echo '#################################################'
echo 'Starting PostgreSQL Master setup for HotStandby1.'
echo '#################################################'

export pg_version='${pg_version}'
export add_iscsi_volume='${add_iscsi_volume}'



echo '--> Updating firewall rules with hotstandby1 IP (${pg_hotstandby_ip}) on master host...'
sudo -u root bash -c "firewall-cmd --permanent --zone=trusted --add-source=${pg_hotstandby_ip}/32"
sudo -u root bash -c "firewall-cmd --permanent --zone=trusted --add-port=5432/tcp"
sudo -u root bash -c "firewall-cmd --reload"
echo '-[100%]-> Firewall updated with hotstandby1 IP (${pg_hotstandby_ip}) on master host.' 

# Create replication user
echo '--> Create replication user...'
chown postgres /tmp/postgresql_master_setup.sql
sudo -u postgres bash -c "psql -d template1 -f /tmp/postgresql_master_setup.sql"
#sudo -u postgres bash -c "psql -U postgres -d postgres -c \"alter user postgres with password '${pg_password}';\""
echo '-[100%]-> Replication user created.' 

if [[ $add_iscsi_volume == "true" ]]; then 
	echo '--> Update the content of postgresql.conf file to support WAL...'
    sudo -u root bash -c "echo 'wal_level = replica' | sudo tee -a /data/pgsql/postgresql.conf"
    sudo -u root bash -c "echo 'archive_mode = on' | sudo tee -a /data/pgsql/postgresql.conf"
    sudo -u root bash -c "echo 'wal_log_hints = on' | sudo tee -a /data/pgsql/postgresql.conf"
    sudo -u root bash -c "echo 'max_wal_senders = 3' | sudo tee -a /data/pgsql/postgresql.conf"
    if [[ $pg_version == "13" ]] || [[ $pg_version == "14" ]] ; then 
	   sudo -u root bash -c "echo 'wal_keep_size = 16MB' | sudo tee -a /data/pgsql/postgresql.conf"
    else
	   sudo -u root bash -c "echo 'wal_keep_segments = 8' | sudo tee -a /data/pgsql/postgresql.conf"
    fi
    sudo -u root bash -c "echo 'hot_standby = on' | sudo tee -a /data/pgsql/postgresql.conf"
    #sudo -u root bash -c "echo 'listen_addresses = '\''0.0.0.0'\'' ' | sudo tee -a /data/pgsql/postgresql.conf"
    sudo -u root bash -c "chown postgres /data/pgsql/postgresql.conf"
    echo '-[100%]-> File postgresql.conf updated with WAL support.' 

    echo '--> Update the content of pg_hba.conf file to include standby host for replication...'
    sudo -u root bash -c "echo 'host replication ${pg_replicat_username} ${pg_hotstandby_ip}/32 md5' | sudo tee -a /data/pgsql/pg_hba.conf" 
    sudo -u root bash -c "echo 'host replication ${pg_replicat_username} ${pg_master_ip}/32 md5' | sudo tee -a /data/pgsql/pg_hba.conf" 
    sudo -u root bash -c "echo 'host all all ${pg_hotstandby_ip}/32 md5' | sudo tee -a /data/pgsql/pg_hba.conf" 
    sudo -u root bash -c "echo 'host all all ${pg_master_ip}/32 md5' | sudo tee -a /data/pgsql/pg_hba.conf" 
    sudo -u root bash -c "echo 'host all all ${node_subnet_cidr} md5' | sudo tee -a /data/pgsql/pg_hba.conf" 
    export pg_whitelisted_ip='${pg_whitelisted_ip}'
	if [[ $pg_whitelisted_ip != "" ]]; then 
    	sudo -u root bash -c "echo 'host all all ${pg_whitelisted_ip}/0 md5' | sudo tee -a /data/pgsql/pg_hba.conf" 
    fi
    sudo -u root bash -c "chown postgres /data/pgsql/pg_hba.conf" 
    echo '-[100%]-> File pg_hba.conf updated with standby host data for replication.' 
else
	echo '--> Update the content of postgresql.conf file to support WAL...'
	sudo -u root bash -c "echo 'wal_level = replica' | sudo tee -a /var/lib/pgsql/${pg_version}/data/postgresql.conf"
	sudo -u root bash -c "echo 'archive_mode = on' | sudo tee -a /var/lib/pgsql/${pg_version}/data/postgresql.conf"
	sudo -u root bash -c "echo 'wal_log_hints = on' | sudo tee -a /var/lib/pgsql/${pg_version}/data/postgresql.conf"
	sudo -u root bash -c "echo 'max_wal_senders = 3' | sudo tee -a /var/lib/pgsql/${pg_version}/data/postgresql.conf"
	if [[ $pg_version == "13" ]] || [[ $pg_version == "14" ]] ; then 
		sudo -u root bash -c "echo 'wal_keep_size = 16MB' | sudo tee -a /var/lib/pgsql/${pg_version}/data/postgresql.conf"
	else
		sudo -u root bash -c "echo 'wal_keep_segments = 8' | sudo tee -a /var/lib/pgsql/${pg_version}/data/postgresql.conf"
	fi
	sudo -u root bash -c "echo 'hot_standby = on' | sudo tee -a /var/lib/pgsql/${pg_version}/data/postgresql.conf"
	#sudo -u root bash -c "echo 'listen_addresses = '\''0.0.0.0'\'' ' | sudo tee -a /var/lib/pgsql/${pg_version}/data/postgresql.conf"
	sudo -u root bash -c "chown postgres /var/lib/pgsql/${pg_version}/data/postgresql.conf"
    echo '-[100%]-> File postgresql.conf updated with WAL support.' 

    echo '--> Update the content of pg_hba.conf file to include standby host for replication...'
	sudo -u root bash -c "echo 'host replication ${pg_replicat_username} ${pg_hotstandby_ip}/32 md5' | sudo tee -a /var/lib/pgsql/${pg_version}/data/pg_hba.conf" 
	sudo -u root bash -c "echo 'host replication ${pg_replicat_username} ${pg_master_ip}/32 md5' | sudo tee -a /var/lib/pgsql/${pg_version}/data/pg_hba.conf" 
	sudo -u root bash -c "echo 'host all all ${pg_hotstandby_ip}/32 md5' | sudo tee -a /var/lib/pgsql/${pg_version}/data/pg_hba.conf" 
	sudo -u root bash -c "echo 'host all all ${pg_master_ip}/32 md5' | sudo tee -a /var/lib/pgsql/${pg_version}/data/pg_hba.conf" 
	sudo -u root bash -c "echo 'host all all ${node_subnet_cidr} md5' | sudo tee -a /var/lib/pgsql/${pg_version}/data/pg_hba.conf" 
	export pg_whitelisted_ip='${pg_whitelisted_ip}'
	if [[ $pg_whitelisted_ip != "" ]]; then 
    	sudo -u root bash -c "echo 'host all all ${pg_whitelisted_ip}/0 md5' | sudo tee -a /var/lib/pgsql/${pg_version}/data/pg_hba.conf" 
    fi
	sudo -u root bash -c "chown postgres /var/lib/pgsql/${pg_version}/data/pg_hba.conf" 
    echo '-[100%]-> File pg_hba.conf updated with standby host data for replication.' 
fi 

echo '--> Restarting PostgreSQL systemctl service...'
sudo systemctl stop postgresql-${pg_version}
sudo systemctl start postgresql-${pg_version}
sudo systemctl status postgresql-${pg_version} --no-pager
echo '-[100%]-> PostgreSQL service restarted.'

echo '#################################################'
echo 'PostgreSQL Master setup for HotStandby1 finished.'
echo '#################################################'

