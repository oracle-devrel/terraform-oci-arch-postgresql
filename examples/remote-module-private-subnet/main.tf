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

resource "oci_core_nat_gateway" "my_nat" {
  compartment_id = var.compartment_ocid
  display_name   = "myNAT"
  vcn_id         = oci_core_virtual_network.my_vcn.id
}

resource "oci_core_route_table" "my_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.my_vcn.id
  display_name   = "myRT"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.my_nat.id
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
  cidr_block                 = "192.168.1.0/24"
  display_name               = "mySubnet"
  dns_label                  = "mysubnet"
  security_list_ids          = [oci_core_security_list.my_securitylist.id]
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_virtual_network.my_vcn.id
  route_table_id             = oci_core_route_table.my_rt.id
  dhcp_options_id            = oci_core_virtual_network.my_vcn.default_dhcp_options_id
  prohibit_public_ip_on_vnic = true
}

module "arch-postgresql" {
  source                   = "github.com/oracle-devrel/terraform-oci-arch-postgresql"
  tenancy_ocid             = var.tenancy_ocid
  user_ocid                = var.user_ocid
  fingerprint              = var.fingerprint
  region                   = var.region
  private_key_path         = var.private_key_path
  availability_domain_name  = var.availability_domain_name
  compartment_ocid         = var.compartment_ocid
  use_existing_vcn         = true                               # usage of the external existing VCN
  create_in_private_subnet = true                               # usage of the private subnet
  postgresql_vcn           = oci_core_virtual_network.my_vcn.id # injecting myVCN
  postgresql_subnet        = oci_core_subnet.my_subnet.id       # injecting private mySubnet 
  postgresql_password      = var.postgresql_password
  add_iscsi_volume         = true # adding iSCSI volume...
  iscsi_volume_size_in_gbs = 200  # ... with 200 GB of size
  postgresql_version       = "12" # non-default version of PostgreSQL12
  
  # OCPUs & memory for flex shape in master node (aarch64/OL8).
  postgresql_instance_shape             = "VM.Standard.A1.Flex"
  postgresql_instance_flex_shape_ocpus  = 2
  postgresql_instance_flex_shape_memory = 20
  # OCPUs & memory for flex shape in hotstanby1 node (aarch64/OL8).
  postgresql_deploy_hotstandby1            = true
  postgresql_hotstandby1_shape             = "VM.Standard.A1.Flex"
  postgresql_hotstandby1_flex_shape_ocpus  = 1
  postgresql_hotstandby1_flex_shape_memory = 10
  # OCPUs & memory for flex shape in hotstanby2 node (aarch64/OL8).
  postgresql_deploy_hotstandby2            = true
  postgresql_hotstandby2_shape             = "VM.Standard.A1.Flex"
  postgresql_hotstandby2_flex_shape_ocpus  = 1
  postgresql_hotstandby2_flex_shape_memory = 5
}

output "generated_ssh_private_key" {
  value     = module.arch-postgresql.generated_ssh_private_key
  sensitive = true
}

output "postgresql_master_session_private_ip" {
  value = module.arch-postgresql.postgresql_master_session_private_ip
}

output "bastion_ssh_postgresql_master_session_metadata" {
  value = module.arch-postgresql.bastion_ssh_postgresql_master_session_metadata
}

output "postgresql_hotstandby1_private_ip" {
  value = module.arch-postgresql.postgresql_hotstandby1_private_ip
}

output "bastion_ssh_postgresql_hotstandby1_session_metadata" {
  value = module.arch-postgresql.bastion_ssh_postgresql_hotstandby1_session_metadata
}

output "postgresql_hotstandby2_private_ip" {
  value = module.arch-postgresql.postgresql_hotstandby2_private_ip
}

output "bastion_ssh_postgresql_hotstandby2_session_metadata" {
  value = module.arch-postgresql.bastion_ssh_postgresql_hotstandby2_session_metadata
}
