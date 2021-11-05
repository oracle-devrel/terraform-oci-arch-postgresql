#!/bin/bash

echo '#####################################'
echo 'Starting PostgreSQL Install Binaries.'
echo '#####################################'

# Install the repository RPM:
sudo yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm

# Install PostgreSQL:
sudo yum install -y postgresql${pg_version_no_dot}-server

# Install PostgreSQL pg_basebackup utility
sudo yum-config-manager --enable ol7_developer
sudo yum-config-manager --enable ol7_developer_EPEL

sudo yum install -y llvm5.0-devel
sudo yum install -y postgresql${pg_version_no_dot}-devel

echo '#####################################'
echo 'PostgreSQL Install Binaries finished.'
echo '#####################################'
