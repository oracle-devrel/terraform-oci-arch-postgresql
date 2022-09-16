## Copyright (c) 2022 Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}
variable "compartment_ocid" {}
variable "availability_domain_name" {}
variable "postgresql_password" {}

terraform {
  required_version = ">= 1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

module "arch-postgresql" {
  source                  = "github.com/oracle-devrel/terraform-oci-arch-postgresql"
  tenancy_ocid            = var.tenancy_ocid
  user_ocid               = var.user_ocid
  fingerprint             = var.fingerprint
  region                  = var.region
  private_key_path        = var.private_key_path
  availability_domain_name = var.availability_domain_name
  compartment_ocid        = var.compartment_ocid
  postgresql_password     = var.postgresql_password
}


output "postgresql_master_session_private_ip" {
  value = module.arch-postgresql.postgresql_master_session_private_ip
}

output "bastion_ssh_postgresql_master_session_metadata" {
  value = module.arch-postgresql.bastion_ssh_postgresql_master_session_metadata
}