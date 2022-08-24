## Copyright (c) 2022 Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

data "template_file" "postgresql_install_binaries_sh" {
  template = file("${path.module}/scripts/postgresql_install_binaries.sh")

  vars = {
    pg_password       = var.postgresql_password
    pg_version_no_dot = replace(var.postgresql_version, ".", "")
    pg_version        = var.postgresql_version
    pg_whitelisted_ip = var.pg_whitelisted_ip
  }
}

data "template_file" "postgresql_master_initdb_sh" {
  template = file("${path.module}/scripts/postgresql_master_initdb.sh")

  vars = {
    pg_password       = var.postgresql_password
    pg_version_no_dot = replace(var.postgresql_version, ".", "")
    pg_version        = var.postgresql_version
    add_iscsi_volume  = var.add_iscsi_volume
  }
}

data "template_file" "postgresql_master_setup_sql" {
  template = file("${path.module}/scripts/postgresql_master_setup.sql")

  vars = {
    pg_replicat_username = var.postgresql_replicat_username
    pg_replicat_password = var.postgresql_password
  }
}

data "template_file" "postgresql_master_setup_sh" {
  count    = var.postgresql_deploy_hotstandby1 ? 1 : 0
  template = file("${path.module}/scripts/postgresql_master_setup.sh")

  vars = {
    pg_master_ip         = data.oci_core_vnic.postgresql_master_primaryvnic.private_ip_address
    pg_hotstandby_ip     = element(data.oci_core_vnic.postgresql_hotstandby1_primaryvnic.*.private_ip_address, 0)
    pg_password          = var.postgresql_password
    pg_version_no_dot    = replace(var.postgresql_version, ".", "")
    pg_version           = var.postgresql_version
    pg_replicat_username = var.postgresql_replicat_username
    node_subnet_cidr     = var.postgresql_subnet_cidr
    add_iscsi_volume     = var.add_iscsi_volume
    pg_whitelisted_ip    = var.pg_whitelisted_ip
  }
}

data "template_file" "postgresql_master_setup2_sh" {
  count    = var.postgresql_deploy_hotstandby2 ? 1 : 0
  template = file("${path.module}/scripts/postgresql_master_setup2.sh")

  vars = {
    pg_master_ip         = data.oci_core_vnic.postgresql_master_primaryvnic.private_ip_address
    pg_hotstandby_ip     = element(data.oci_core_vnic.postgresql_hotstandby2_primaryvnic.*.private_ip_address, 0)
    pg_version           = var.postgresql_version
    pg_replicat_username = var.postgresql_replicat_username
    add_iscsi_volume     = var.add_iscsi_volume
  }
}

data "template_file" "postgresql_standby_setup_sh" {
  count    = var.postgresql_deploy_hotstandby1 ? 1 : 0
  template = file("${path.module}/scripts/postgresql_standby_setup.sh")

  vars = {
    pg_master_ip         = data.oci_core_vnic.postgresql_master_primaryvnic.private_ip_address
    pg_hotstandby_ip     = element(data.oci_core_vnic.postgresql_hotstandby1_primaryvnic.*.private_ip_address, 0)
    pg_password          = var.postgresql_password
    pg_version_no_dot    = replace(var.postgresql_version, ".", "")
    pg_version           = var.postgresql_version
    pg_replicat_username = var.postgresql_replicat_username
    pg_replicat_password = var.postgresql_password
    add_iscsi_volume     = var.add_iscsi_volume
  }
}

resource "null_resource" "postgresql_master_attach_volume" {

  triggers = {
    postgresql_master_id = oci_core_instance.postgresql_master.id
  }

  count      = var.add_iscsi_volume ? 1 : 0
  depends_on = [oci_core_instance.postgresql_master, oci_core_volume.postgresql_master_volume, oci_core_volume_attachment.postgresql_master_volume_attachment]

  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_master_primaryvnic.private_ip_address : data.oci_core_vnic.postgresql_master_primaryvnic.public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_master_session[0].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }
    inline = ["sudo /bin/su -c \"rm -rf /home/opc/iscsiattach.sh\""]
  }

  provisioner "file" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_master_primaryvnic.private_ip_address : data.oci_core_vnic.postgresql_master_primaryvnic.public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_master_session[0].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }
    source      = "${path.module}/scripts/iscsiattach.sh"
    destination = "/home/opc/iscsiattach.sh"
  }

  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_master_primaryvnic.private_ip_address : data.oci_core_vnic.postgresql_master_primaryvnic.public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_master_session[0].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }
    inline = ["sudo /bin/su -c \"chown root /home/opc/iscsiattach.sh\"",
      "sudo /bin/su -c \"chmod u+x /home/opc/iscsiattach.sh\"",
    "sudo /bin/su -c \"/home/opc/iscsiattach.sh\""]
  }

  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_master_primaryvnic.private_ip_address : data.oci_core_vnic.postgresql_master_primaryvnic.public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_master_session[0].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }
    inline = [
      "sudo -u root parted /dev/sdb --script -- mklabel gpt",
      "sudo -u root parted /dev/sdb --script -- mkpart primary ext4 0% 100%",
      "sudo -u root mkfs.ext4 /dev/sdb1 -F",
      "sudo -u root mkdir /data",
      "sudo -u root mount /dev/sdb1 /data",
      "sudo /bin/su -c \"echo '/dev/sdb1              /data  ext4    defaults,noatime,_netdev    0   0' >> /etc/fstab\"",
      "sudo -u root mount | grep sdb1",
    ]
  }

}

resource "null_resource" "postgresql_master_install_binaries" {

  triggers = {
    postgresql_master_id = oci_core_instance.postgresql_master.id
  }

  depends_on = [oci_core_instance.postgresql_master, null_resource.postgresql_master_attach_volume]

  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_master_primaryvnic.private_ip_address : data.oci_core_vnic.postgresql_master_primaryvnic.public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_master_session[0].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }
    inline = [
      "sudo rm -rf /home/opc/postgresql_install_binaries.sh"
    ]
  }

  provisioner "file" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_master_primaryvnic.private_ip_address : data.oci_core_vnic.postgresql_master_primaryvnic.public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_master_session[0].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }

    content     = data.template_file.postgresql_install_binaries_sh.rendered
    destination = "/home/opc/postgresql_install_binaries.sh"
  }

  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_master_primaryvnic.private_ip_address : data.oci_core_vnic.postgresql_master_primaryvnic.public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_master_session[0].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }
    inline = [
      "chmod +x /home/opc/postgresql_install_binaries.sh",
      "sudo /home/opc/postgresql_install_binaries.sh"
    ]
  }
}

resource "null_resource" "postgresql_master_initdb" {

  triggers = {
    postgresql_master_id = oci_core_instance.postgresql_master.id
  }

  depends_on = [null_resource.postgresql_master_install_binaries]

  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_master_primaryvnic.private_ip_address : data.oci_core_vnic.postgresql_master_primaryvnic.public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_master_session[0].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }
    inline = [
      "sudo rm -rf /home/opc/postgresql_master_initdb.sh"
    ]
  }

  provisioner "file" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_master_primaryvnic.private_ip_address : data.oci_core_vnic.postgresql_master_primaryvnic.public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_master_session[0].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }

    content     = data.template_file.postgresql_master_initdb_sh.rendered
    destination = "/home/opc/postgresql_master_initdb.sh"
  }

  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_master_primaryvnic.private_ip_address : data.oci_core_vnic.postgresql_master_primaryvnic.public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_master_session[0].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }
    inline = [
      "chmod +x /home/opc/postgresql_master_initdb.sh",
      "sudo /home/opc/postgresql_master_initdb.sh"
    ]
  }
}

resource "null_resource" "postgresql_hotstandby1_install_binaries" {

  triggers = {
    postgresql_hotstandby1_id = oci_core_instance.postgresql_hotstandby1[0].id
  }

  count      = var.postgresql_deploy_hotstandby1 ? 1 : 0
  depends_on = [oci_core_instance.postgresql_master, oci_core_instance.postgresql_hotstandby1, null_resource.postgresql_hotstandby1_attach_volume]

  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_hotstandby1_primaryvnic[count.index].private_ip_address : data.oci_core_vnic.postgresql_hotstandby1_primaryvnic[count.index].public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_hotstandby1_session[count.index].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }
    inline = [
      "sudo rm -rf /home/opc/postgresql_install_binaries.sh"
    ]
  }

  provisioner "file" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_hotstandby1_primaryvnic[count.index].private_ip_address : data.oci_core_vnic.postgresql_hotstandby1_primaryvnic[count.index].public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_hotstandby1_session[count.index].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }

    content     = data.template_file.postgresql_install_binaries_sh.rendered
    destination = "/home/opc/postgresql_install_binaries.sh"
  }

  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_hotstandby1_primaryvnic[count.index].private_ip_address : data.oci_core_vnic.postgresql_hotstandby1_primaryvnic[count.index].public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_hotstandby1_session[count.index].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }
    inline = [
      "chmod +x /home/opc/postgresql_install_binaries.sh",
      "sudo /home/opc/postgresql_install_binaries.sh"
    ]
  }
}

resource "null_resource" "postgresql_hotstandby2_install_binaries" {

  triggers = {
    postgresql_hotstandby2_id = oci_core_instance.postgresql_hotstandby2[0].id
  }

  count      = var.postgresql_deploy_hotstandby2 ? 1 : 0
  depends_on = [oci_core_instance.postgresql_master, oci_core_instance.postgresql_hotstandby2, null_resource.postgresql_hotstandby2_attach_volume]

  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_hotstandby2_primaryvnic[count.index].private_ip_address : data.oci_core_vnic.postgresql_hotstandby2_primaryvnic[count.index].public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_hotstandby2_session[count.index].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }
    inline = [
      "sudo rm -rf /home/opc/postgresql_install_binaries.sh"
    ]
  }

  provisioner "file" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_hotstandby2_primaryvnic[count.index].private_ip_address : data.oci_core_vnic.postgresql_hotstandby2_primaryvnic[count.index].public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_hotstandby2_session[count.index].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }

    content     = data.template_file.postgresql_install_binaries_sh.rendered
    destination = "/home/opc/postgresql_install_binaries.sh"
  }

  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_hotstandby2_primaryvnic[count.index].private_ip_address : data.oci_core_vnic.postgresql_hotstandby2_primaryvnic[count.index].public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_hotstandby2_session[count.index].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }
    inline = [
      "chmod +x /home/opc/postgresql_install_binaries.sh",
      "sudo /home/opc/postgresql_install_binaries.sh"
    ]
  }
}


resource "null_resource" "postgresql_master_setup" {

  triggers = {
    postgresql_master_id = oci_core_instance.postgresql_master.id
  }

  count      = var.postgresql_deploy_hotstandby1 ? 1 : 0
  depends_on = [null_resource.postgresql_master_initdb, null_resource.postgresql_hotstandby1_install_binaries]

  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_master_primaryvnic.private_ip_address : data.oci_core_vnic.postgresql_master_primaryvnic.public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_master_session[0].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }
    inline = [
      "sudo rm -rf /home/opc/postgresql_master_setup.sh",
      "sudo rm -rf /tmp/postgresql_master_setup_sql",
    ]
  }

  provisioner "file" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_master_primaryvnic.private_ip_address : data.oci_core_vnic.postgresql_master_primaryvnic.public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_master_session[0].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }

    content     = element(data.template_file.postgresql_master_setup_sh.*.rendered, 0)
    destination = "/home/opc/postgresql_master_setup.sh"
  }

  provisioner "file" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_master_primaryvnic.private_ip_address : data.oci_core_vnic.postgresql_master_primaryvnic.public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_master_session[0].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }

    content     = element(data.template_file.postgresql_master_setup_sql.*.rendered, 0)
    destination = "/tmp/postgresql_master_setup.sql"
  }

  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_master_primaryvnic.private_ip_address : data.oci_core_vnic.postgresql_master_primaryvnic.public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_master_session[0].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }
    inline = [
      "chmod +x /home/opc/postgresql_master_setup.sh",
      "sudo /home/opc/postgresql_master_setup.sh"
    ]
  }
}

resource "null_resource" "postgresql_master_setup2" {

  triggers = {
    postgresql_master_id = oci_core_instance.postgresql_master.id
  }

  count      = var.postgresql_deploy_hotstandby2 ? 1 : 0
  depends_on = [null_resource.postgresql_master_initdb, null_resource.postgresql_hotstandby2_install_binaries, null_resource.postgresql_master_setup, null_resource.postgresql_hotstandby1_setup]

  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_master_primaryvnic.private_ip_address : data.oci_core_vnic.postgresql_master_primaryvnic.public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_master_session[0].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }
    inline = [
      "sudo rm -rf /home/opc/postgresql_master_setup2.sh",
    ]
  }

  provisioner "file" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_master_primaryvnic.private_ip_address : data.oci_core_vnic.postgresql_master_primaryvnic.public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_master_session[0].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }

    content     = element(data.template_file.postgresql_master_setup2_sh.*.rendered, 0)
    destination = "/home/opc/postgresql_master_setup2.sh"
  }

  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_master_primaryvnic.private_ip_address : data.oci_core_vnic.postgresql_master_primaryvnic.public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_master_session[0].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }
    inline = [
      "chmod +x /home/opc/postgresql_master_setup2.sh",
      "sudo /home/opc/postgresql_master_setup2.sh"
    ]
  }
}


resource "null_resource" "postgresql_hotstandby1_attach_volume" {

  triggers = {
    postgresql_hotstandby1_id = oci_core_instance.postgresql_hotstandby1[0].id
  }

  count      = (var.postgresql_deploy_hotstandby1 && var.add_iscsi_volume) ? 1 : 0
  depends_on = [oci_core_instance.postgresql_hotstandby1, oci_core_volume.postgresql_hotstandby1_volume, oci_core_volume_attachment.postgresql_hotstandby1_volume_attachment]

  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_hotstandby1_primaryvnic[count.index].private_ip_address : data.oci_core_vnic.postgresql_hotstandby1_primaryvnic[count.index].public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_hotstandby1_session[count.index].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }
    inline = ["sudo /bin/su -c \"rm -rf /home/opc/iscsiattach.sh\""]
  }

  provisioner "file" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_hotstandby1_primaryvnic[count.index].private_ip_address : data.oci_core_vnic.postgresql_hotstandby1_primaryvnic[count.index].public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_hotstandby1_session[count.index].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }
    source      = "${path.module}/scripts/iscsiattach.sh"
    destination = "/home/opc/iscsiattach.sh"
  }

  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_hotstandby1_primaryvnic[count.index].private_ip_address : data.oci_core_vnic.postgresql_hotstandby1_primaryvnic[count.index].public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_hotstandby1_session[count.index].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }
    inline = ["sudo /bin/su -c \"chown root /home/opc/iscsiattach.sh\"",
      "sudo /bin/su -c \"chmod u+x /home/opc/iscsiattach.sh\"",
    "sudo /bin/su -c \"/home/opc/iscsiattach.sh\""]
  }

  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_hotstandby1_primaryvnic[count.index].private_ip_address : data.oci_core_vnic.postgresql_hotstandby1_primaryvnic[count.index].public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_hotstandby1_session[count.index].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }
    inline = [
      "sudo -u root parted /dev/sdb --script -- mklabel gpt",
      "sudo -u root parted /dev/sdb --script -- mkpart primary ext4 0% 100%",
      "sudo -u root mkfs.ext4 /dev/sdb1 -F",
      "sudo -u root mkdir /data",
      "sudo -u root mount /dev/sdb1 /data",
      "sudo /bin/su -c \"echo '/dev/sdb1              /data  ext4    defaults,noatime,_netdev    0   0' >> /etc/fstab\"",
      "sudo -u root mount | grep sdb1",
    ]
  }
}

resource "null_resource" "postgresql_hotstandby1_setup" {

  triggers = {
    postgresql_hotstandby1_id = oci_core_instance.postgresql_hotstandby1[0].id
  }

  count      = var.postgresql_deploy_hotstandby1 ? 1 : 0
  depends_on = [null_resource.postgresql_master_setup, null_resource.postgresql_hotstandby1_install_binaries, null_resource.postgresql_hotstandby1_attach_volume]

  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_hotstandby1_primaryvnic[count.index].private_ip_address : data.oci_core_vnic.postgresql_hotstandby1_primaryvnic[count.index].public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_hotstandby1_session[count.index].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }
    inline = [
      "sudo rm -rf /home/opc/postgresql_standby_setup.sh",
    ]
  }

  provisioner "file" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_hotstandby1_primaryvnic[count.index].private_ip_address : data.oci_core_vnic.postgresql_hotstandby1_primaryvnic[count.index].public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_hotstandby1_session[count.index].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }

    content     = element(data.template_file.postgresql_standby_setup_sh.*.rendered, 0)
    destination = "/home/opc/postgresql_standby_setup.sh"
  }

  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_hotstandby1_primaryvnic[count.index].private_ip_address : data.oci_core_vnic.postgresql_hotstandby1_primaryvnic[count.index].public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_hotstandby1_session[count.index].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }
    inline = [
      "chmod +x /home/opc/postgresql_standby_setup.sh",
      "sudo /home/opc/postgresql_standby_setup.sh"
    ]
  }
}

resource "null_resource" "postgresql_hotstandby2_attach_volume" {

  triggers = {
    postgresql_hotstandby2_id = oci_core_instance.postgresql_hotstandby2[0].id
  }

  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_hotstandby2_primaryvnic[count.index].private_ip_address : data.oci_core_vnic.postgresql_hotstandby2_primaryvnic[count.index].public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_hotstandby2_session[count.index].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }
    inline = ["sudo /bin/su -c \"rm -rf /home/opc/iscsiattach.sh\""]
  }

  count      = (var.postgresql_deploy_hotstandby2 && var.add_iscsi_volume) ? 1 : 0
  depends_on = [oci_core_instance.postgresql_hotstandby2, oci_core_volume.postgresql_hotstandby2_volume, oci_core_volume_attachment.postgresql_hotstandby2_volume_attachment]

  provisioner "file" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_hotstandby2_primaryvnic[count.index].private_ip_address : data.oci_core_vnic.postgresql_hotstandby2_primaryvnic[count.index].public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_hotstandby2_session[count.index].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }
    source      = "${path.module}/scripts/iscsiattach.sh"
    destination = "/home/opc/iscsiattach.sh"
  }

  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_hotstandby2_primaryvnic[count.index].private_ip_address : data.oci_core_vnic.postgresql_hotstandby2_primaryvnic[count.index].public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_hotstandby2_session[count.index].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }
    inline = ["sudo /bin/su -c \"chown root /home/opc/iscsiattach.sh\"",
      "sudo /bin/su -c \"chmod u+x /home/opc/iscsiattach.sh\"",
    "sudo /bin/su -c \"/home/opc/iscsiattach.sh\""]
  }

  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_hotstandby2_primaryvnic[count.index].private_ip_address : data.oci_core_vnic.postgresql_hotstandby2_primaryvnic[count.index].public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_hotstandby2_session[count.index].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }
    inline = [
      "sudo -u root parted /dev/sdb --script -- mklabel gpt",
      "sudo -u root parted /dev/sdb --script -- mkpart primary ext4 0% 100%",
      "sudo -u root mkfs.ext4 /dev/sdb1 -F",
      "sudo -u root mkdir /data",
      "sudo -u root mount /dev/sdb1 /data",
      "sudo /bin/su -c \"echo '/dev/sdb1              /data  ext4    defaults,noatime,_netdev    0   0' >> /etc/fstab\"",
      "sudo -u root mount | grep sdb1",
    ]
  }
}

resource "null_resource" "postgresql_hotstandby2_setup" {

  triggers = {
    postgresql_hotstandby2_id = oci_core_instance.postgresql_hotstandby2[0].id
  }

  count      = var.postgresql_deploy_hotstandby2 ? 1 : 0
  depends_on = [null_resource.postgresql_master_setup2, null_resource.postgresql_hotstandby1_setup, null_resource.postgresql_hotstandby2_install_binaries, null_resource.postgresql_hotstandby2_attach_volume]

  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_hotstandby2_primaryvnic[count.index].private_ip_address : data.oci_core_vnic.postgresql_hotstandby2_primaryvnic[count.index].public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_hotstandby2_session[count.index].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }
    inline = [
      "sudo rm -rf /home/opc/postgresql_standby_setup.sh",
    ]
  }

  provisioner "file" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_hotstandby2_primaryvnic[count.index].private_ip_address : data.oci_core_vnic.postgresql_hotstandby2_primaryvnic[count.index].public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_hotstandby2_session[count.index].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }

    content     = element(data.template_file.postgresql_standby_setup_sh.*.rendered, 0)
    destination = "/home/opc/postgresql_standby_setup.sh"
  }

  provisioner "remote-exec" {
    connection {
      type                = "ssh"
      user                = "opc"
      host                = var.create_in_private_subnet ? data.oci_core_vnic.postgresql_hotstandby2_primaryvnic[count.index].private_ip_address : data.oci_core_vnic.postgresql_hotstandby2_primaryvnic[count.index].public_ip_address
      private_key         = tls_private_key.public_private_key_pair.private_key_pem
      script_path         = "/home/opc/myssh.sh"
      agent               = false
      timeout             = "10m"
      bastion_host        = var.create_in_private_subnet ? "host.bastion.${var.region}.oci.oraclecloud.com" : null
      bastion_port        = var.create_in_private_subnet ? "22" : null
      bastion_user        = var.create_in_private_subnet ? oci_bastion_session.ssh_postgresql_hotstandby2_session[count.index].id : null
      bastion_private_key = var.create_in_private_subnet ? tls_private_key.public_private_key_pair.private_key_pem : null
    }
    inline = [
      "chmod +x /home/opc/postgresql_standby_setup.sh",
      "sudo /home/opc/postgresql_standby_setup.sh"
    ]
  }
}
