## Copyright (c) 2022 Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

output "PostgreSQL_Master_VM_public_IP" {
  value = data.oci_core_vnic.postgresql_master_primaryvnic.public_ip_address
}

output "PostgreSQL_Username" {
  value = "postgres"
}

output "generated_ssh_private_key" {
  value     = tls_private_key.public_private_key_pair.private_key_pem
  sensitive = true
}

output "bastion_ssh_postgresql_master_session_metadata" {
  value = oci_bastion_session.ssh_postgresql_master_session.*.ssh_metadata
}

output "bastion_ssh_postgresql_hotstandby1_session_metadata" {
  value = oci_bastion_session.ssh_postgresql_hotstandby1_session.*.ssh_metadata
}

output "bastion_ssh_postgresql_hotstandby2_session_metadata" {
  value = oci_bastion_session.ssh_postgresql_hotstandby2_session.*.ssh_metadata
}
