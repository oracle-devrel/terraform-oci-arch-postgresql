#!/bin/bash

echo '#####################################'
echo 'Starting PostgreSQL Master initdb.'
echo '#####################################'

export pg_version='${pg_version}'
export add_iscsi_volume='${add_iscsi_volume}'

echo '--> Optionally initialize the database and enable automatic start...'
if [[ $pg_version == "9.6" ]]; then 
	sudo /usr/pgsql-${pg_version}/bin/postgresql${pg_version_no_dot}-setup initdb
	echo '-[100%]-> PostgreSQL Setup InitDB successfully finished.' 
else
	sudo /usr/pgsql-${pg_version}/bin/postgresql-${pg_version_no_dot}-setup initdb
	echo '-[100%]-> PostgreSQL Setup InitDB successfully finished.'
fi	



export pg_whitelist_cidr='${pg_whitelist_cidr}'
if [[ $add_iscsi_volume == "true" ]]; then
	echo '--> Adding iSCSI volume to PostgreSQL configuration...'
	sudo mkdir /data/pgsql
	sudo chown -R postgres:postgres /data/pgsql
	sudo -u postgres bash -c "/usr/pgsql-${pg_version_no_dot}/bin/initdb --pgdata=/data/pgsql"
	sudo sed -i 's/Environment=PGDATA=\/var\/lib\/pgsql\/${pg_version_no_dot}\/data\//Environment=PGDATA=\/data\/pgsql\//g' /usr/lib/systemd/system/postgresql-${pg_version_no_dot}.service 
	echo '-[100%]-> iSCSI volume added to PostgreSQL configuration.'
	sudo -u root bash -c "echo 'listen_addresses = '\''0.0.0.0'\'' ' | sudo tee -a /data/pgsql/postgresql.conf"
	sudo sed -i 's/^max_connections = [0-9]\+/max_connections = 200/' /data/pgsql/postgresql.conf
	if [[ $pg_whitelist_cidr != "" ]]; then
		sudo -u root bash -c "echo 'host all all ${pg_whitelist_cidr} md5' | sudo tee -a /data/pgsql/pg_hba.conf"
	fi
else
	sudo sed -i 's/^max_connections = [0-9]\+/max_connections = 200/' /var/lib/pgsql/${pg_version}/data/postgresql.conf
	sudo -u root bash -c "echo 'listen_addresses = '\''0.0.0.0'\'' ' | sudo tee -a /var/lib/pgsql/${pg_version}/data/postgresql.conf"
	if [[ $pg_whitelist_cidr != "" ]]; then
		sudo -u root bash -c "echo 'host all all ${pg_whitelist_cidr} md5' | sudo tee -a /var/lib/pgsql/${pg_version}/data/pg_hba.conf"
	fi
fi

echo '--> Enabling and starting PostgreSQL systemctl service...'
sudo systemctl enable postgresql-${pg_version}
sudo systemctl start postgresql-${pg_version}
sudo systemctl status postgresql-${pg_version} --no-pager
echo '-[100%]-> PostgreSQL service started.'




echo '--> Change password of postgres user...'
echo "postgres:${pg_password}" | chpasswd
echo '-[100%]-> postgres user password changed.' 


echo '--> Change postgres db password...'
sudo -u postgres bash -c "psql -U postgres -d postgres -c \"alter user postgres with password '${pg_password}';\""
echo '-[100%]-> Password for postgres updated.' 



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






echo '#####################################'
echo 'PostgreSQL Master initdb finished.'
echo '#####################################'