## Copyright (c) 2022 Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

data "template_file" "key_script" {
  template = file("${path.module}/scripts/sshkey.tpl")
  vars = {
    ssh_public_key = tls_private_key.public_private_key_pair.public_key_openssh
  }
}

data "template_cloudinit_config" "cloud_init" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "ainit.sh"
    content_type = "text/x-shellscript"
    content      = data.template_file.key_script.rendered
  }
}

resource "oci_core_instance" "postgresql_master" {
  availability_domain = var.availability_domain_name
  compartment_id      = var.compartment_ocid
  display_name        = "PostgreSQL_Master"
  shape               = var.postgresql_instance_shape

  dynamic "shape_config" {
    for_each = local.is_flexible_postgresql_instance_shape ? [1] : []
    content {
      memory_in_gbs = var.postgresql_instance_flex_shape_memory
      ocpus         = var.postgresql_instance_flex_shape_ocpus
    }
  }

  dynamic "agent_config" {
    for_each = var.create_in_private_subnet ? [1] : []
    content {
      are_all_plugins_disabled = false
      is_management_disabled   = false
      is_monitoring_disabled   = false
      plugins_config {
        desired_state = "ENABLED"
        name          = "Bastion"
      }
    }
  }

  fault_domain = var.postgresql_master_fd

  create_vnic_details {
    subnet_id        = !var.use_existing_vcn ? oci_core_subnet.postgresql_subnet[0].id : var.postgresql_subnet
    display_name     = "primaryvnic"
    assign_public_ip = var.create_in_private_subnet ? false : true
    hostname_label   = "pgmaster"
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.InstanceImageOCID_postgresql_instance_shape.images[0].id
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = data.template_cloudinit_config.cloud_init.rendered
  }

  provisioner "local-exec" {
    command = "sleep 240"
  }

  defined_tags = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

resource "oci_core_boot_volume_backup" "postgresql_master_boot_volume_backup" {
  count          = var.boot_volume_initial_backup ? 1 : 0
  boot_volume_id = oci_core_instance.postgresql_master.boot_volume_id
  display_name   = "PostgreSQL_Master_Boot_Volume_Backup_FULL"
  type           = "FULL"
}

resource "oci_core_volume_backup_policy_assignment" "postgresql_master_boot_volume_backup_policy_assignment" {
  count     = var.boot_volume_backup_policy_enabled ? 1 : 0
  asset_id  = oci_core_instance.postgresql_master.boot_volume_id
  policy_id = data.oci_core_volume_backup_policies.boot_volume_backup_policy.volume_backup_policies[0].id
}

resource "oci_core_instance" "postgresql_hotstandby1" {
  count               = var.postgresql_deploy_hotstandby1 ? 1 : 0
  availability_domain = var.postgresql_hotstandby1_ad == "" ? var.availability_domain_name : var.postgresql_hotstandby1_ad
  compartment_id      = var.compartment_ocid
  display_name        = "PostgreSQL_HotStandby1"
  shape               = var.postgresql_hotstandby1_shape

  dynamic "shape_config" {
    for_each = local.is_flexible_postgresql_hotstandby1_shape ? [1] : []
    content {
      memory_in_gbs = var.postgresql_hotstandby1_flex_shape_memory
      ocpus         = var.postgresql_hotstandby1_flex_shape_ocpus
    }
  }

  dynamic "agent_config" {
    for_each = var.create_in_private_subnet ? [1] : []
    content {
      are_all_plugins_disabled = false
      is_management_disabled   = false
      is_monitoring_disabled   = false
      plugins_config {
        desired_state = "ENABLED"
        name          = "Bastion"
      }
    }
  }


  fault_domain = var.postgresql_hotstandby1_fd

  create_vnic_details {
    subnet_id        = !var.use_existing_vcn ? oci_core_subnet.postgresql_subnet[0].id : var.postgresql_subnet
    display_name     = "primaryvnic"
    assign_public_ip = var.create_in_private_subnet ? false : true
    hostname_label   = "pgstandby1"
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.InstanceImageOCID_postgresql_hotstandby1_shape.images[0].id
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = data.template_cloudinit_config.cloud_init.rendered
  }

  provisioner "local-exec" {
    command = "sleep 240"
  }

  defined_tags = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

resource "oci_core_boot_volume_backup" "postgresql_hotstandby1_boot_volume_backup" {
  count          = (var.postgresql_deploy_hotstandby1 && var.boot_volume_initial_backup) ? 1 : 0
  boot_volume_id = oci_core_instance.postgresql_hotstandby1[0].boot_volume_id
  display_name   = "PostgreSQL_Hotstandby1_Boot_Volume_Backup_FULL"
  type           = "FULL"
}

resource "oci_core_volume_backup_policy_assignment" "postgresql_hotstandby1_boot_volume_backup_policy_assignment" {
  count     = (var.postgresql_deploy_hotstandby1 && var.boot_volume_backup_policy_enabled) ? 1 : 0
  asset_id  = oci_core_instance.postgresql_hotstandby1[0].boot_volume_id
  policy_id = data.oci_core_volume_backup_policies.boot_volume_backup_policy.volume_backup_policies[0].id
}

resource "oci_core_instance" "postgresql_hotstandby2" {
  count               = var.postgresql_deploy_hotstandby2 ? 1 : 0
  availability_domain = var.postgresql_hotstandby2_ad == "" ? var.availability_domain_name : var.postgresql_hotstandby2_ad
  compartment_id      = var.compartment_ocid
  display_name        = "PostgreSQL_HotStandby2"
  shape               = var.postgresql_hotstandby2_shape

  dynamic "shape_config" {
    for_each = local.is_flexible_postgresql_hotstandby2_shape ? [1] : []
    content {
      memory_in_gbs = var.postgresql_hotstandby2_flex_shape_memory
      ocpus         = var.postgresql_hotstandby2_flex_shape_ocpus
    }
  }


  dynamic "agent_config" {
    for_each = var.create_in_private_subnet ? [1] : []
    content {
      are_all_plugins_disabled = false
      is_management_disabled   = false
      is_monitoring_disabled   = false
      plugins_config {
        desired_state = "ENABLED"
        name          = "Bastion"
      }
    }
  }

  fault_domain = var.postgresql_hotstandby2_fd

  create_vnic_details {
    subnet_id        = !var.use_existing_vcn ? oci_core_subnet.postgresql_subnet[0].id : var.postgresql_subnet
    display_name     = "primaryvnic"
    assign_public_ip = var.create_in_private_subnet ? false : true
    hostname_label   = "pgstandby2"
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.InstanceImageOCID_postgresql_hotstandby2_shape.images[0].id
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = data.template_cloudinit_config.cloud_init.rendered
  }

  provisioner "local-exec" {
    command = "sleep 240"
  }

  defined_tags = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

resource "oci_core_boot_volume_backup" "postgresql_hotstandby2_boot_volume_backup" {
  count          = (var.postgresql_deploy_hotstandby2 && var.boot_volume_initial_backup) ? 1 : 0
  boot_volume_id = oci_core_instance.postgresql_hotstandby2[0].boot_volume_id
  display_name   = "PostgreSQL_Hotstandby2_Boot_Volume_Backup_FULL"
  type           = "FULL"
}

resource "oci_core_volume_backup_policy_assignment" "postgresql_hotstandby2_boot_volume_backup_policy_assignment" {
  count     = (var.postgresql_deploy_hotstandby2 && var.boot_volume_backup_policy_enabled) ? 1 : 0
  asset_id  = oci_core_instance.postgresql_hotstandby2[0].boot_volume_id
  policy_id = data.oci_core_volume_backup_policies.boot_volume_backup_policy.volume_backup_policies[0].id
}
