## Copyright (c) 2021 Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}
variable "compartment_ocid" {}
variable "availablity_domain_name" {}
variable "postgresql_password" {}

variable "postgresql_instance_shape" {
  default = "VM.Standard.A1.Flex"
}

variable "postgresql_instance_flex_shape_ocpus" {
  default = 1
}

variable "postgresql_instance_flex_shape_memory" {
  default = 6
}

variable "postgresql_hotstandby1_shape" {
  default = "VM.Standard.A1.Flex"
}

variable "postgresql_hotstandby1_flex_shape_ocpus" {
  default = 1
}

variable "postgresql_hotstandby1_flex_shape_memory" {
  default = 2
}

variable "postgresql_hotstandby2_shape" {
  default = "VM.Standard.A1.Flex"
}

variable "postgresql_hotstandby2_flex_shape_ocpus" {
  default = 1
}

variable "postgresql_hotstandby2_flex_shape_memory" {
  default = 2
}

variable "linux_os_version" {
  default = "8"
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

resource "oci_core_virtual_network" "my_vcn" {
  cidr_block     = "192.168.0.0/16"
  compartment_id = var.compartment_ocid
  display_name   = "myVCN"
  dns_label      = "myvcn"
}

resource "oci_core_internet_gateway" "my_igw" {
  compartment_id = var.compartment_ocid
  display_name   = "myIGW"
  vcn_id         = oci_core_virtual_network.my_vcn.id
}

resource "oci_core_route_table" "my_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.my_vcn.id
  display_name   = "myRT"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.my_igw.id
  }
}

resource "oci_core_security_list" "my_securitylist" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.my_vcn.id
  display_name   = "mySecurityList"

  egress_security_rules {
    protocol    = "6"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      max = "22"
      min = "22"
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      max = "5432"
      min = "5432"
    }
  }
}

resource "oci_core_subnet" "my_subnet" {
  cidr_block        = "192.168.1.0/24"
  display_name      = "mySubnet"
  dns_label         = "mysubnet"
  security_list_ids = [oci_core_security_list.my_securitylist.id]
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_virtual_network.my_vcn.id
  route_table_id    = oci_core_route_table.my_rt.id
  dhcp_options_id   = oci_core_virtual_network.my_vcn.default_dhcp_options_id
}

module "arch-postgresql" {
  source                                  = "github.com/oracle-devrel/terraform-oci-arch-postgresql"
  tenancy_ocid                             = var.tenancy_ocid
  user_ocid                                = var.user_ocid
  fingerprint                              = var.fingerprint
  region                                   = var.region
  private_key_path                         = var.private_key_path
  availablity_domain_name                  = var.availablity_domain_name
  compartment_ocid                         = var.compartment_ocid
  postgresql_instance_shape                = var.postgresql_instance_shape
  postgresql_instance_flex_shape_ocpus     = var.postgresql_instance_flex_shape_ocpus
  postgresql_instance_flex_shape_memory    = var.postgresql_instance_flex_shape_memory
  postgresql_hotstandby1_shape             = var.postgresql_hotstandby1_shape
  postgresql_hotstandby1_flex_shape_ocpus  = var.postgresql_hotstandby1_flex_shape_ocpus
  postgresql_hotstandby1_flex_shape_memory = var.postgresql_hotstandby1_flex_shape_memory
  postgresql_hotstandby2_shape             = var.postgresql_hotstandby2_shape
  postgresql_hotstandby2_flex_shape_ocpus  = var.postgresql_hotstandby2_flex_shape_ocpus
  postgresql_hotstandby2_flex_shape_memory = var.postgresql_hotstandby2_flex_shape_memory
  use_existing_vcn                         = true                               # usage of the external existing VCN
  create_in_private_subnet                 = false                              # usage of the public subnet
  postgresql_vcn                           = oci_core_virtual_network.my_vcn.id # injecting myVCN
  postgresql_subnet                        = oci_core_subnet.my_subnet.id       # injecting public mySubnet 
  postgresql_password                      = var.postgresql_password
  postgresql_deploy_hotstandby1            = true
  postgresql_deploy_hotstandby2            = true
}

output "generated_ssh_private_key" {
  value     = module.arch-postgresql.generated_ssh_private_key
  sensitive = true
}

output "postgresql_master_session_private_ip" {
  value = module.arch-postgresql.postgresql_master_session_private_ip
}

output "postgresql_master_session_public_ip" {
  value = module.arch-postgresql.postgresql_master_session_public_ip
}

output "postgresql_hotstandby1_public_ip" {
  value = module.arch-postgresql.postgresql_hotstandby1_public_ip
}

output "postgresql_hotstandby1_private_ip" {
  value = module.arch-postgresql.postgresql_hotstandby1_private_ip
}

output "postgresql_hotstandby2_public_ip" {
  value = module.arch-postgresql.postgresql_hotstandby2_public_ip
}

output "postgresql_hotstandby2_private_ip" {
  value = module.arch-postgresql.postgresql_hotstandby2_private_ip
}