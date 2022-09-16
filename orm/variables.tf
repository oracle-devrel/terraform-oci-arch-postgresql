## Copyright (c) 2022 Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

variable "tenancy_ocid" {}
#variable "user_ocid" {}
#variable "fingerprint" {}
#variable "private_key_path" {}
variable "region" {}
variable "compartment_ocid" {}
variable "availability_domain_name" {}

variable "release" {
  description = "Reference Architecture Release (OCI Architecture Center)"
  default     = "1.6"
}

variable "use_existing_vcn" {
  default = false
}

variable "pg_whitelisted_ip" {
  description = "Should be Public host IP Address like 89.64.91.8"
  default     = ""
}

variable "postgresql_vcn" {
  default = ""
}

variable "postgresql_subnet" {
  default = ""
}

variable "show_advanced" {
  default = false
}

variable "create_in_private_subnet" {
  default = true
}

variable "create_drg_for_private_subnet" {
  default = false
}

variable "ssh_public_key" {
  default = ""
}

variable "postgresql_vcn_cidr" {
  default = "10.1.0.0/16"
}

variable "postgresql_subnet_cidr" {
  default = "10.1.20.0/24"
}

variable "postgresql_instance_shape" {
  default = "VM.Standard.E4.Flex"
}

variable "postgresql_instance_flex_shape_ocpus" {
  default = 1
}

variable "postgresql_instance_flex_shape_memory" {
  default = 10
}

variable "instance_os" {
  description = "Operating system for compute instances"
  default     = "Oracle Linux"
}

variable "linux_os_version" {
  description = "Operating system version for all Linux instances"
  default     = "9"
}

variable "postgresql_master_fd" {
  default = "FAULT-DOMAIN-1"
}

variable "postgresql_replicat_username" {
  default = "replicator"
}

variable "postgresql_password" {
  default = ""
}

variable "postgresql_version" {
  default = "13"
}

variable "add_iscsi_volume" {
  default = true
}

variable "iscsi_volume_size_in_gbs" {
  default = 100
}

variable "boot_volume_backup_policy_enabled" {
  default = true
}

variable "boot_volume_backup_policy_level" {
  default = "gold"
}

variable "boot_volume_initial_backup" {
  default = true
}

variable "block_volume_backup_policy_enabled" {
  default = true
}

variable "block_volume_backup_policy_level" {
  default = "gold"
}

variable "block_volume_initial_backup" {
  default = true
}

variable "postgresql_deploy_hotstandby1" {
  default = false
}

variable "postgresql_hotstandby1_fd" {
  default = "FAULT-DOMAIN-2"
}

variable "postgresql_hotstandby1_ad" {
  default = ""
}

variable "postgresql_hotstandby1_shape" {
  default = "VM.Standard.E4.Flex"
}

variable "postgresql_hotstandby1_flex_shape_ocpus" {
  default = 1
}

variable "postgresql_hotstandby1_flex_shape_memory" {
  default = 10
}

variable "postgresql_deploy_hotstandby2" {
  default = false
}

variable "postgresql_hotstandby2_fd" {
  default = "FAULT-DOMAIN-3"
}

variable "postgresql_hotstandby2_ad" {
  default = ""
}

variable "postgresql_hotstandby2_shape" {
  default = "VM.Standard.E4.Flex"
}

variable "postgresql_hotstandby2_flex_shape_ocpus" {
  default = 1
}

variable "postgresql_hotstandby2_flex_shape_memory" {
  default = 10
}

# Dictionary Locals
locals {
  compute_flexible_shapes = [
    "VM.Standard.E3.Flex",
    "VM.Standard.E4.Flex",
    "VM.Standard.A1.Flex"
  ]
}

# Checks if is using Flexible Compute Shapes
locals {
  is_flexible_postgresql_instance_shape    = contains(local.compute_flexible_shapes, var.postgresql_instance_shape)
  is_flexible_postgresql_hotstandby1_shape = contains(local.compute_flexible_shapes, var.postgresql_hotstandby1_shape)
  is_flexible_postgresql_hotstandby2_shape = contains(local.compute_flexible_shapes, var.postgresql_hotstandby2_shape)
}
