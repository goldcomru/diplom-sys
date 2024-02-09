terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  service_account_key_file = file("key.json")
  cloud_id                 = "b1g7v71fbt127vf1efa3"
  folder_id                = "b1gmfqs3c5o3re1g6r1g"
  zone                     = "ru-central1-a"
}


#-----------Создание приватной сети------------

resource "yandex_vpc_network" "diplom-network" {
  name = "diplom-network"
}

#-----------Создание внутренних и внешней подсетей------------

resource "yandex_vpc_subnet" "external-subnet" {
  name           = "external-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.diplom-network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_vpc_subnet" "internal-subnet-1" {
  name           = "internal-subnet-1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.diplom-network.id
  v4_cidr_blocks = ["192.168.20.0/24"]
  route_table_id = yandex_vpc_route_table.instance-route.id
}


resource "yandex_vpc_subnet" "internal-subnet-2" {
  name           = "internal-subnet-2"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.diplom-network.id
  v4_cidr_blocks = ["192.168.30.0/24"]
  route_table_id = yandex_vpc_route_table.instance-route.id
}


#-----------Группа безопасности Bastion-external-security------------

resource "yandex_vpc_security_group" "bastion-external-security" {
  name        = "bastion-external-security"
  description = "Public Group Bastion"
  network_id  = yandex_vpc_network.diplom-network.id

  ingress {
    protocol       = "ANY"
    description    = "Rule description 1"
    v4_cidr_blocks = ["0.0.0.0/0"]
	port           = 22
  }

  egress {
    protocol       = "ANY"
    description    = "Rule description 2"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}


#-----------Создание ВМ Bastion------------

resource "yandex_compute_instance" "bastion" {
  name     = "bastion"
  hostname = "bastion"
  zone     = "ru-central1-a"

  resources {
    cores         = 2
    core_fraction = 20
    memory        = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd83hfj7tqogennmsjoa"
      size     = 10
    }
  }
  network_interface {
    subnet_id          = yandex_vpc_subnet.external-subnet.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.bastion-external-security.id]
  }
  metadata = {
    user-data = "${file("./metadata.yml")}"
  }
}

#-----------Создание статичной маршрутизации------------


resource "yandex_vpc_route_table" "instance-route" {
  name       = "instance-route"
  network_id = yandex_vpc_network.diplom-network.id
  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = yandex_compute_instance.bastion.network_interface.0.ip_address
  }
}

