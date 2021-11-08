ALTER SYSTEM SET listen_addresses TO '*';
CREATE USER ${pg_replicat_username} REPLICATION LOGIN ENCRYPTED PASSWORD '${pg_replicat_password}';

