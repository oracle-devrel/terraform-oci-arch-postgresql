## Copyright (c) 2021 Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

data "oci_core_vnic_attachments" "postgresql_master_vnics" {
  compartment_id      = var.compartment_ocid
  availability_domain = var.availablity_domain_name
  instance_id         = oci_core_instance.postgresql_master.id
}


data "oci_core_vnic_attachments" "postgresql_master_primaryvnic_attach" {
  availability_domain = var.availablity_domain_name
  compartment_id      = var.compartment_ocid
  instance_id         = oci_core_instance.postgresql_master.id
}

data "oci_core_vnic" "postgresql_master_primaryvnic" {
  vnic_id = data.oci_core_vnic_attachments.postgresql_master_primaryvnic_attach.vnic_attachments.0.vnic_id
}

data "oci_core_vnic_attachments" "postgresql_hotstandby1_primaryvnic_attach" {
  count               = var.postgresql_deploy_hotstandby1 ? 1 : 0
  availability_domain = var.postgresql_hotstandby1_ad
  compartment_id      = var.compartment_ocid
  instance_id         = oci_core_instance.postgresql_hotstandby1[count.index].id
}

data "oci_core_vnic" "postgresql_hotstandby1_primaryvnic" {
  count   = var.postgresql_deploy_hotstandby1 ? 1 : 0
  vnic_id = data.oci_core_vnic_attachments.postgresql_hotstandby1_primaryvnic_attach[count.index].vnic_attachments.0.vnic_id
}

data "oci_core_vnic_attachments" "postgresql_hotstandby2_primaryvnic_attach" {
  count               = var.postgresql_deploy_hotstandby2 ? 1 : 0
  availability_domain = var.postgresql_hotstandby2_ad
  compartment_id      = var.compartment_ocid
  instance_id         = oci_core_instance.postgresql_hotstandby2[count.index].id
}

data "oci_core_vnic" "postgresql_hotstandby2_primaryvnic" {
  count   = var.postgresql_deploy_hotstandby2 ? 1 : 0
  vnic_id = data.oci_core_vnic_attachments.postgresql_hotstandby2_primaryvnic_attach[count.index].vnic_attachments.0.vnic_id
}


# Get the latest Oracle Linux image
data "oci_core_images" "InstanceImageOCID_postgresql_instance_shape" {
  compartment_id           = var.compartment_ocid
  operating_system         = var.instance_os
  operating_system_version = var.linux_os_version
  shape                    = var.postgresql_instance_shape

  filter {
    name   = "display_name"
    values = ["^.*Oracle[^G]*$"]
    regex  = true
  }
}

# Get the latest Oracle Linux image
data "oci_core_images" "InstanceImageOCID_postgresql_hotstandby1_shape" {
  compartment_id           = var.compartment_ocid
  operating_system         = var.instance_os
  operating_system_version = var.linux_os_version
  shape                    = var.postgresql_hotstandby1_shape

  filter {
    name   = "display_name"
    values = ["^.*Oracle[^G]*$"]
    regex  = true
  }
}

# Get the latest Oracle Linux image
data "oci_core_images" "InstanceImageOCID_postgresql_hotstandby2_shape" {
  compartment_id           = var.compartment_ocid
  operating_system         = var.instance_os
  operating_system_version = var.linux_os_version
  shape                    = var.postgresql_hotstandby2_shape

  filter {
    name   = "display_name"
    values = ["^.*Oracle[^G]*$"]
    regex  = true
  }
}

data "oci_identity_region_subscriptions" "home_region_subscriptions" {
  tenancy_id = var.tenancy_ocid

  filter {
    name   = "is_home_region"
    values = [true]
  }
}


data "oci_core_volume_backup_policies" "boot_volume_backup_policy" {
  #  count = var.add_iscsi_volume ? 1 : 0

  filter {
    name   = "display_name"
    values = [var.boot_volume_backup_policy_level]
    regex  = true
  }
}


data "oci_core_volume_backup_policies" "block_volume_backup_policy" {
  count = var.add_iscsi_volume ? 1 : 0

  filter {
    name   = "display_name"
    values = [var.block_volume_backup_policy_level]
    regex  = true
  }
}
