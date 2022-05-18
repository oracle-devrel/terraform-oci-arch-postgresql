## Copyright (c) 2022 Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

data "oci_computeinstanceagent_instance_agent_plugins" "postgresql_master_agent_plugin_bastion" {
  count            = var.create_in_private_subnet ? 1 : 0
  compartment_id   = var.compartment_ocid
  instanceagent_id = oci_core_instance.postgresql_master.id
  name             = "Bastion"
  status           = "RUNNING"
}

data "oci_computeinstanceagent_instance_agent_plugins" "postgresql_hotstandby1_agent_plugin_bastion" {
  count            = (var.create_in_private_subnet && var.postgresql_deploy_hotstandby1) ? 1 : 0
  compartment_id   = var.compartment_ocid
  instanceagent_id = oci_core_instance.postgresql_hotstandby1[count.index].id
  name             = "Bastion"
  status           = "RUNNING"
}

data "oci_computeinstanceagent_instance_agent_plugins" "postgresql_hotstandby2_agent_plugin_bastion" {
  count            = (var.create_in_private_subnet && var.postgresql_deploy_hotstandby2) ? 1 : 0
  compartment_id   = var.compartment_ocid
  instanceagent_id = oci_core_instance.postgresql_hotstandby2[count.index].id
  name             = "Bastion"
  status           = "RUNNING"
}

resource "time_sleep" "postgresql_master_agent_checker" {
  depends_on      = [oci_core_instance.postgresql_master]
  count           = var.create_in_private_subnet ? 1 : 0
  create_duration = "60s"

  triggers = {
    changed_time_stamp = length(data.oci_computeinstanceagent_instance_agent_plugins.postgresql_master_agent_plugin_bastion) != 0 ? 0 : timestamp()
    instance_ocid  = oci_core_instance.postgresql_master.id
  }
}

resource "time_sleep" "postgresql_hotstandby1_agent_checker" {
  depends_on      = [oci_core_instance.postgresql_hotstandby1]
  count           = (var.create_in_private_subnet && var.postgresql_deploy_hotstandby1) ? 1 : 0
  create_duration = "60s"

  triggers = {
    changed_time_stamp = length(data.oci_computeinstanceagent_instance_agent_plugins.postgresql_hotstandby1_agent_plugin_bastion) != 0 ? 0 : timestamp()
    instance_ocid  = oci_core_instance.postgresql_hotstandby1.0.id
  }
}

resource "time_sleep" "postgresql_hotstandby2_agent_checker" {
  depends_on      = [oci_core_instance.postgresql_hotstandby2]
  count           = (var.create_in_private_subnet && var.postgresql_deploy_hotstandby2) ? 1 : 0
  create_duration = "60s"

  triggers = {
    changed_time_stamp = length(data.oci_computeinstanceagent_instance_agent_plugins.postgresql_hotstandby2_agent_plugin_bastion) != 0 ? 0 : timestamp()
    instance_ocid  = oci_core_instance.postgresql_hotstandby2.0.id
  }
}

resource "oci_bastion_bastion" "bastion-service" {
  count                        = var.create_in_private_subnet ? 1 : 0
  bastion_type                 = "STANDARD"
  compartment_id               = var.compartment_ocid
  target_subnet_id             = !var.use_existing_vcn ? oci_core_subnet.postgresql_subnet[0].id : var.postgresql_subnet
  client_cidr_block_allow_list = ["0.0.0.0/0"]
  defined_tags                 = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
  name                         = "BastionService${random_id.tag.hex}"
  max_session_ttl_in_seconds   = 10800
}

resource "oci_bastion_session" "ssh_postgresql_master_session" {
  depends_on = [oci_core_instance.postgresql_master,
    oci_core_nat_gateway.postgresql_nat,
    oci_core_route_table.postgresql_rt2
  ]

  count      = var.create_in_private_subnet ? 1 : 0
  bastion_id = oci_bastion_bastion.bastion-service[0].id

  key_details {
    public_key_content = tls_private_key.public_private_key_pair.public_key_openssh
  }
  target_resource_details {
    target_resource_id = time_sleep.postgresql_master_agent_checker[count.index].triggers["instance_ocid"]
    session_type       = "MANAGED_SSH"

    target_resource_operating_system_user_name = "opc"
    target_resource_port                       = 22
    target_resource_private_ip_address         = oci_core_instance.postgresql_master.private_ip
  }

  display_name           = "ssh_postgresql_master_session"
  key_type               = "PUB"
  session_ttl_in_seconds = 10800
}

resource "oci_bastion_session" "ssh_postgresql_hotstandby1_session" {
  depends_on = [oci_core_instance.postgresql_master,
    oci_core_nat_gateway.postgresql_nat,
    oci_core_route_table.postgresql_rt2
  ]

  count      = (var.create_in_private_subnet && var.postgresql_deploy_hotstandby1) ? 1 : 0
  bastion_id = oci_bastion_bastion.bastion-service[0].id

  key_details {
    public_key_content = tls_private_key.public_private_key_pair.public_key_openssh
  }
  target_resource_details {
    target_resource_id = time_sleep.postgresql_hotstandby1_agent_checker[count.index].triggers["instance_ocid"]
    session_type       = "MANAGED_SSH"

    target_resource_operating_system_user_name = "opc"
    target_resource_port                       = 22
    target_resource_private_ip_address         = oci_core_instance.postgresql_hotstandby1[count.index].private_ip
  }

  display_name           = "ssh_postgresql_hotstandby1_session"
  key_type               = "PUB"
  session_ttl_in_seconds = 10800
}

resource "oci_bastion_session" "ssh_postgresql_hotstandby2_session" {
  depends_on = [oci_core_instance.postgresql_master,
    oci_core_nat_gateway.postgresql_nat,
    oci_core_route_table.postgresql_rt2
  ]

  count      = (var.create_in_private_subnet && var.postgresql_deploy_hotstandby2) ? 1 : 0
  bastion_id = oci_bastion_bastion.bastion-service[0].id

  key_details {
    public_key_content = tls_private_key.public_private_key_pair.public_key_openssh
  }
  target_resource_details {
    target_resource_id = time_sleep.postgresql_hotstandby2_agent_checker[count.index].triggers["instance_ocid"]
    session_type       = "MANAGED_SSH"

    target_resource_operating_system_user_name = "opc"
    target_resource_port                       = 22
    target_resource_private_ip_address         = oci_core_instance.postgresql_hotstandby2[count.index].private_ip
  }

  display_name           = "ssh_postgresql_hotstandby2_session"
  key_type               = "PUB"
  session_ttl_in_seconds = 10800
}
