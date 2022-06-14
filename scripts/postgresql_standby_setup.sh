#!/bin/bash

echo '#################################################'
echo 'Starting PostgreSQL Standby Setup for HotStandby.'
echo '#################################################'

export pg_version='${pg_version}'
export add_iscsi_volume='${add_iscsi_volume}'

echo '--> Change password of postgres user...'
echo "postgres:${pg_password}" | chpasswd
echo '-[100%]-> postgres user password changed.' 

echo '--> Updating firewall rules with master IP (${pg_master_ip}) on standby host...'
sudo -u root bash -c "firewall-cmd --permanent --zone=trusted --add-source=${pg_master_ip}/32"
sudo -u root bash -c "firewall-cmd --permanent --zone=trusted --add-port=5432/tcp"
sudo -u root bash -c "firewall-cmd --reload"
echo '-[100%]-> Firewall updated with hotstandby IP (${pg_hotstandby_ip}) on standby host.' 

if [[ $add_iscsi_volume == "true" ]]; then 
	echo '--> Creating database on the volume...'
	sudo mkdir /data/pgsql
	sudo chown -R postgres:postgres /data/pgsql
	sudo -u postgres bash -c "/usr/pgsql-${pg_version_no_dot}/bin/initdb --pgdata=/data/pgsql"
	sudo sed -i 's/Environment=PGDATA=\/var\/lib\/pgsql\/${pg_version_no_dot}\/data\//Environment=PGDATA=\/data\/pgsql\//g' /usr/lib/systemd/system/postgresql-${pg_version_no_dot}.service 
    echo '-[100%]-> Database created.' 

	echo '--> Taking initial backup of database...'
	sudo -u root bash -c "rm -rf /data/pgsql/*"
	sudo -u postgres bash -c "export PGPASSWORD=${pg_replicat_password}; pg_basebackup -D /data/pgsql/ -h ${pg_master_ip} -X stream -c fast -U ${pg_replicat_username}"
	echo '-[100%]-> Initial backup of database taken.'

	echo '--> Updating content of recovery.conf/postgresql.conf files...'
	if [[ $pg_version == "13" ]]; then 
		touch /data/pgsql/standby.signal
		touch /data/pgsql/recovery.signal
		sudo -u root bash -c "echo 'primary_conninfo  = '\''host=${pg_master_ip} port=5432 user=${pg_replicat_username} password=${pg_replicat_password}'\'' ' | sudo tee -a /data/pgsql/postgresql.conf"
    	sudo -u root bash -c "echo 'recovery_target_timeline = '\''latest'\'' ' | sudo tee -a /data/pgsql/postgresql.conf"
    	sudo -u root bash -c "chown postgres /data/pgsql/postgresql.conf"
	elif [[ $pg_version == "12"  ]]; then
		touch /data/pgsql/standby.signal
		touch /data/pgsql/recovery.signal
		sudo -u root bash -c "echo 'primary_conninfo  = '\''host=${pg_master_ip} port=5432 user=${pg_replicat_username} password=${pg_replicat_password}'\'' ' | sudo tee -a /data/pgsql/postgresql.conf"
    	sudo -u root bash -c "echo 'recovery_target_timeline = '\''latest'\'' ' | sudo tee -a /data/pgsql/postgresql.conf"
    	sudo -u root bash -c "chown postgres /data/pgsql/postgresql.conf"
	else
		sudo -u root bash -c "echo 'standby_mode = '\''on'\'' ' | sudo tee -a /data/pgsql/recovery.conf" 
    	sudo -u root bash -c "echo 'primary_conninfo  = '\''host=${pg_master_ip} port=5432 user=${pg_replicat_username} password=${pg_replicat_password}'\'' ' | sudo tee -a /data/pgsql/recovery.conf"
    	sudo -u root bash -c "echo 'recovery_target_timeline = '\''latest'\'' ' | sudo tee -a /data/pgsql/recovery.conf"
    	sudo -u root bash -c "chown postgres /data/pgsql/recovery.conf"
	fi
	echo '-[100%]-> Files recovery.conf/postgresql.conf updated.'
else 
	echo '--> Taking initial backup of database...'
	sudo -u root bash -c "rm -rf /var/lib/pgsql/${pg_version}/data/*"
	sudo -u postgres bash -c "export PGPASSWORD=${pg_replicat_password}; pg_basebackup -D /var/lib/pgsql/${pg_version}/data/ -h ${pg_master_ip} -X stream -c fast -U ${pg_replicat_username}"
	echo '-[100%]-> Initial backup of database taken.'	

	echo '--> Updating content of recovery.conf/postgresql.conf files...'
	if [[ $pg_version == "13" ]]; then 
		touch /var/lib/pgsql/${pg_version}/data/standby.signal
		touch /var/lib/pgsql/${pg_version}/data/recovery.signal
		sudo -u root bash -c "echo 'primary_conninfo  = '\''host=${pg_master_ip} port=5432 user=${pg_replicat_username} password=${pg_replicat_password}'\'' ' | sudo tee -a /var/lib/pgsql/${pg_version}/data/postgresql.conf"
    	sudo -u root bash -c "echo 'recovery_target_timeline = '\''latest'\'' ' | sudo tee -a /var/lib/pgsql/${pg_version}/data/postgresql.conf"
    	sudo -u root bash -c "chown postgres /var/lib/pgsql/${pg_version}/data/postgresql.conf"
	elif [[ $pg_version == "12"  ]]; then
		touch /var/lib/pgsql/${pg_version}/data/standby.signal
		touch /var/lib/pgsql/${pg_version}/data/recovery.signal
		sudo -u root bash -c "echo 'primary_conninfo  = '\''host=${pg_master_ip} port=5432 user=${pg_replicat_username} password=${pg_replicat_password}'\'' ' | sudo tee -a /var/lib/pgsql/${pg_version}/data/postgresql.conf"
    	sudo -u root bash -c "echo 'recovery_target_timeline = '\''latest'\'' ' | sudo tee -a /var/lib/pgsql/${pg_version}/data/postgresql.conf"
    	sudo -u root bash -c "chown postgres /var/lib/pgsql/${pg_version}/data/postgresql.conf"
	else
		sudo -u root bash -c "echo 'standby_mode = '\''on'\'' ' | sudo tee -a /var/lib/pgsql/${pg_version}/data/recovery.conf" 
    	sudo -u root bash -c "echo 'primary_conninfo  = '\''host=${pg_master_ip} port=5432 user=${pg_replicat_username} password=${pg_replicat_password}'\'' ' | sudo tee -a /var/lib/pgsql/${pg_version}/data/recovery.conf"
    	sudo -u root bash -c "echo 'recovery_target_timeline = '\''latest'\'' ' | sudo tee -a /var/lib/pgsql/${pg_version}/data/recovery.conf"
    	sudo -u root bash -c "chown postgres /var/lib/pgsql/${pg_version}/data/recovery.conf"
	fi
	echo '-[100%]-> Files recovery.conf/postgresql.conf updated.'
fi

echo '--> Restarting PostgreSQL systemctl service...'
sudo systemctl enable postgresql-${pg_version}
sudo systemctl stop postgresql-${pg_version}
sudo systemctl start postgresql-${pg_version}
sudo systemctl status postgresql-${pg_version} --no-pager
echo '-[100%]-> PostgreSQL service restarted.'

echo '--> Showing the logs of PostgreSQL with tail -5 command...'
if [[ $pg_version == "9.6" ]]; then 
	if [[ $add_iscsi_volume == "true" ]]; then 
		sudo -u root bash -c "tail -5 /data/pgsql/log/postgresql-*.log"
	else
		sudo -u root bash -c "tail -5 /var/lib/pgsql/${pg_version}/data/pg_log/postgresql-*.log"
    fi 
else
	if [[ $add_iscsi_volume == "true" ]]; then 
		sudo -u root bash -c "tail -5 /data/pgsql/log/postgresql-*.log"
	else 
		sudo -u root bash -c "tail -5 /var/lib/pgsql/${pg_version}/data/log/postgresql-*.log"
	fi
fi
echo '-[100%]-> PostgreSQL logs printed out.'

echo '#################################################'
echo 'PostgreSQL Standby Setup for HotStandby finished.'
echo '#################################################'
