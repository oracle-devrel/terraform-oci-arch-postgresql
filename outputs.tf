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

output "postgresql_master_session_private_ip" {
  value = oci_core_instance.postgresql_master.private_ip
}

output "postgresql_hotstandby1_private_ip" {
  value = var.postgresql_deploy_hotstandby1 ? oci_core_instance.postgresql_hotstandby1.*.private_ip : [""]
}

output "postgresql_hotstandby2_private_ip" {
  value = var.postgresql_deploy_hotstandby2 ? oci_core_instance.postgresql_hotstandby2.*.private_ip : [""]
}

output "postgresql_master_session_public_ip" {
  value = !var.create_in_private_subnet ? oci_core_instance.postgresql_master.public_ip : ""
}

output "postgresql_hotstandby1_public_ip" {
  value = var.postgresql_deploy_hotstandby1 && !var.create_in_private_subnet ? oci_core_instance.postgresql_hotstandby1.*.public_ip : [""]
}

output "postgresql_hotstandby2_public_ip" {
  value = var.postgresql_deploy_hotstandby2 && !var.create_in_private_subnet ? oci_core_instance.postgresql_hotstandby2.*.public_ip : [""]
}