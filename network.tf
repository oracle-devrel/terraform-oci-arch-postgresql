## Copyright (c) 2021 Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_core_virtual_network" "postgresql_vcn" {
  count          = !var.use_existing_vcn ? 1 : 0
  cidr_block     = var.postgresql_vcn_cidr
  compartment_id = var.compartment_ocid
  display_name   = "PostgreSQLVCN"
  dns_label      = "postgresvcn"
  defined_tags   = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

resource "oci_core_drg" "postgresql_drg" {
  count          = (var.create_in_private_subnet && var.create_drg_for_private_subnet && !var.use_existing_vcn) ? 1 : 0
  compartment_id = var.compartment_ocid
  display_name   = "PostgreSQLDRG"
  defined_tags   = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

resource "oci_core_drg_attachment" "postgresql_drg_attachment" {
  count        = (var.create_in_private_subnet && var.create_drg_for_private_subnet && !var.use_existing_vcn) ? 1 : 0
  drg_id       = oci_core_drg.postgresql_drg[0].id
  vcn_id       = oci_core_virtual_network.postgresql_vcn[0].id
  display_name = "PostgreSQLDRG_Attachment"
}

resource "oci_core_internet_gateway" "postgresql_igw" {
  count          = (!var.create_in_private_subnet && !var.use_existing_vcn) ? 1 : 0
  compartment_id = var.compartment_ocid
  display_name   = "PostgreSQLIGW"
  vcn_id         = oci_core_virtual_network.postgresql_vcn[0].id
  defined_tags   = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

resource "oci_core_route_table" "postgresql_rt" {
  count          = (!var.create_in_private_subnet && !var.use_existing_vcn) ? 1 : 0
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.postgresql_vcn[0].id
  display_name   = "PostgreSQLRouteTable"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.postgresql_igw[count.index].id
  }
  defined_tags = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

resource "oci_core_nat_gateway" "postgresql_nat" {
  count          = (var.create_in_private_subnet && !var.use_existing_vcn) ? 1 : 0
  compartment_id = var.compartment_ocid
  display_name   = "PostgreSQLNAT"
  vcn_id         = oci_core_virtual_network.postgresql_vcn[0].id
  defined_tags   = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

resource "oci_core_route_table" "postgresql_rt2" {
  count          = (var.create_in_private_subnet && !var.use_existing_vcn) ? 1 : 0
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.postgresql_vcn[0].id
  display_name   = "PostgreSQLRouteTable2"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.postgresql_nat[count.index].id
  }
  defined_tags = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

resource "oci_core_subnet" "postgresql_subnet" {
  count                      = !var.use_existing_vcn ? 1 : 0
  cidr_block                 = var.postgresql_subnet_cidr
  display_name               = "PostgreSQLSubnet"
  dns_label                  = "postgressubnet"
  security_list_ids          = [oci_core_security_list.postgresql_securitylist[0].id]
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_virtual_network.postgresql_vcn[0].id
  route_table_id             = var.create_in_private_subnet ? oci_core_route_table.postgresql_rt2[0].id : oci_core_route_table.postgresql_rt[0].id
  dhcp_options_id            = oci_core_virtual_network.postgresql_vcn[0].default_dhcp_options_id
  prohibit_public_ip_on_vnic = var.create_in_private_subnet ? true : false
  defined_tags               = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

