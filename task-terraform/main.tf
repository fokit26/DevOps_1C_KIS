terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = "ru-central1-b"
}

variable "mem" {
  type=number
  default = 2
}
variable "storage" {
  type=number
  default = 20
}
variable "core" {
  type=number
  default=2
}


resource "yandex_compute_instance" "webapp-1" {
  name = "webapp-1"
  resources {
    memory = var.mem
    cores = var.core
  }
  boot_disk {
    disk_id = yandex_compute_disk.ubuntu-1.id
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat = true
  }
  metadata = {
    "ssh-keys" = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
  }
}

resource "yandex_compute_instance" "webapp-2" {
  name = "webapp-2"
  resources {
    memory = var.mem
    cores = var.core
  }
  boot_disk {
    disk_id = yandex_compute_disk.ubuntu-2.id
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat = true
  }
  metadata = {
    "ssh-keys" = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
  }
}

resource "yandex_compute_disk" "ubuntu-1" {
    name="ubuntu-1"
    size = var.storage
    image_id = "fd85m9q2qspfnsv055rh"
}
resource "yandex_compute_disk" "ubuntu-2" {
    name="ubuntu-2"
    size = var.storage
    image_id = "fd85m9q2qspfnsv055rh"
}

resource "yandex_vpc_subnet" "subnet-1" {
    name = "subnet-1"
    network_id = yandex_vpc_network.network-1.id

    v4_cidr_blocks = ["192.168.10.0/24"]
    zone = "ru-central1-b"
}

resource "yandex_vpc_network" "network-1" {
    name = "network-1"
}
output "terraform_i_v-1" {
    value = yandex_compute_instance.webapp-1.network_interface.0.nat_ip_address
}

output "terraform_ip_v-2" {
    value = yandex_compute_instance.webapp-2.network_interface.0.nat_ip_address
}

resource "yandex_mdb_postgresql_cluster" "cluster" {
  name                = "cluster"
  environment         = "PRODUCTION"
  network_id          = yandex_vpc_network.network-1.id
  deletion_protection = false

  config {
    version = "15"
    resources {
      resource_preset_id = "b1.medium"
      disk_type_id       = "network-hdd"
      disk_size          = var.storage
    }
  }

  host {
    zone             = "ru-central1-b"
    name             = "host1"
    subnet_id        = yandex_vpc_subnet.subnet-1.id
    assign_public_ip = true
  }
}

resource "yandex_mdb_postgresql_database" "db" {
  cluster_id = yandex_mdb_postgresql_cluster.cluster.id
  name       = "db"
  owner      = "app_admin"
  depends_on = [
    yandex_mdb_postgresql_user.postgres
  ]
}

resource "yandex_mdb_postgresql_user" "postgres" {
  cluster_id = yandex_mdb_postgresql_cluster.cluster.id
  name       = "app_admin"
  password   = "secure_password_123"
}

resource "yandex_api_gateway" "web-gateway" {
  name        = "web-gateway"
  description = "API Gateway for web applications"
  
  spec = templatefile("${path.module}/api_gateway_spec.yaml", {
    webapp1_ip = yandex_compute_instance.webapp-1.network_interface.0.ip_address
    webapp2_ip = yandex_compute_instance.webapp-2.network_interface.0.ip_address
  })
}

output "api_gateway_domain" {
  value = yandex_api_gateway.web-gateway.domain
}