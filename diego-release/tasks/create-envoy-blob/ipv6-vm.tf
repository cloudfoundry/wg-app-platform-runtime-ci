terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.52"
    }
  }
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
}

variable "env_id" {
  type = string
}

variable "credentials" {
  type = string
}

variable "gce_ssh_user" {
  type = string
}

variable "gce_ssh_pub_key_file" {
  type = string
}

provider "google" {
  credentials = "${file("${var.credentials}")}"
  project     = "${var.project_id}"
  region      = "${var.region}"
}

variable "ipv6_subnet_cidr" {
  type    = string
  default = "10.60.0.0/24"
}

resource "google_compute_network" "ipv6-net" {
  name                     = "${var.env_id}-ipv6-net"
  auto_create_subnetworks  = false
  enable_ula_internal_ipv6 = true
}

resource "google_compute_subnetwork" "ipv6-subnet" {
  name             = "${var.env_id}-ipv6-subnet"
  ip_cidr_range    = "${var.ipv6_subnet_cidr}"
  network          = "${google_compute_network.ipv6-net.self_link}"
  stack_type       = "IPV4_IPV6"
  ipv6_access_type = "INTERNAL"
}

resource "google_compute_firewall" "external" {
  name    = "${var.env_id}-external"
  network = "${google_compute_network.ipv6-net.name}"

  source_ranges = ["0.0.0.0/0"]

  allow {
    ports    = ["22"]
    protocol = "tcp"
  }

  target_tags = ["${var.env_id}-ssh-open"]
}

resource "google_compute_address" "ip" {
  name = "${var.env_id}-ip"
}

resource "google_compute_instance" "vm" {
  name         = "${var.env_id}-vm"
  machine_type = "e2-standard-16"
  zone         = "${var.zone}"
  allow_stopping_for_update = true

  tags = ["${var.env_id}-ssh-open"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-pro-cloud/ubuntu-pro-1804-lts"
      size = "400"
    }
  }

  network_interface {
    network = "${google_compute_network.ipv6-net.self_link}"
    subnetwork = "${google_compute_subnetwork.ipv6-subnet.self_link}"
    stack_type = "IPV4_IPV6"

    access_config {
      nat_ip = "${google_compute_address.ip.address}"
    }
  }

  metadata = {
    ssh-keys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }
}

output "external_ip" {
  value = "${google_compute_address.ip.address}"
}
