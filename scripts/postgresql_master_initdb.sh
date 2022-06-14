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

if [[ $add_iscsi_volume == "true" ]]; then 
	echo '--> Adding iSCSI volume to PostgreSQL configuration...'
	sudo mkdir /data/pgsql
	sudo chown -R postgres:postgres /data/pgsql
	sudo -u postgres bash -c "/usr/pgsql-${pg_version_no_dot}/bin/initdb --pgdata=/data/pgsql"
	sudo sed -i 's/Environment=PGDATA=\/var\/lib\/pgsql\/${pg_version_no_dot}\/data\//Environment=PGDATA=\/data\/pgsql\//g' /usr/lib/systemd/system/postgresql-${pg_version_no_dot}.service 
	echo '-[100%]-> iSCSI volume added to PostgreSQL configuration.'
fi

echo '--> Enabling and starting PostgreSQL systemctl service...'
sudo systemctl enable postgresql-${pg_version}
sudo systemctl start postgresql-${pg_version}
sudo systemctl status postgresql-${pg_version} --no-pager
echo '-[100%]-> PostgreSQL service started.'

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