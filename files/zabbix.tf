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

#-----------Группа безопасности Zabbix------------

resource "yandex_vpc_security_group" "zabbix-security" {
  name        = "zabbix-security"
  description = "Public Group Bastion"
  network_id  = "enp64t1jdhvoiv2i565h"

  ingress {
    protocol       = "ANY"
    description    = "Rule description 1"
    v4_cidr_blocks = ["0.0.0.0/0"]
	port           = 10050
  }
  
  ingress {
    protocol       = "ANY"
    description    = "ssh"
    v4_cidr_blocks = ["0.0.0.0/0"]
	port           = 22
  }

  egress {
    protocol       = "ANY"
    description    = "Rule description 2"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

#-----------Создание ВМ Zabbix------------

resource "yandex_compute_instance" "zabbix" {
  name = "zabbix"
  hostname = "zabbix"
  zone = "ru-central1-a"
  
  resources{
    cores = 2
    core_fraction = 20
    memory = 4
  }

  boot_disk{
    initialize_params {
      image_id = "fd8ecgtorub9r4609man"
      size = 10
    }
  }
  network_interface {
    subnet_id = "e9bpn4ar1bfmppt8b66o"
    nat = true
#	security_group_ids = [yandex_vpc_security_group.zabbix-security.id]
  }
  metadata = {
    user-data = "${file("./metadata.yml")}"
  }
}





