terraform {
  required_providers {
    vsphere = {
      source = "hashicorp/vsphere"
      version = "2.0.2"
    }
  }
}

provider "vsphere" {
  user           = var.vsphere_user
  password       = var.vsphere_password
  vsphere_server = var.vsphere_server

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = "mel-dc-ng-datacenter"
}

data "vsphere_datastore" "datastore" {
  name          = "cgascoig-1"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = "Melb-HX-Hybrid"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = "vm-network-28"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "web-template" {
  name          = "carsales-web-image"
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "web" {
  count = var.num_vms

  name             = "ico-its-${count.index}"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus = 2
  memory   = 1024
  guest_id = data.vsphere_virtual_machine.web-template.guest_id

  scsi_type = data.vsphere_virtual_machine.web-template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.web-template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.web-template.disks.0.size
    eagerly_scrub    = data.vsphere_virtual_machine.web-template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.web-template.disks.0.thin_provisioned
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.web-template.id
  }
}