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


#-----------Группа безопасности L7-балансировщика------------------------

resource "yandex_vpc_security_group" "balancer-security" {
  name        = "balancer-security"
  description = "Balancer"
  network_id  = "enp64t1jdhvoiv2i565h"

  ingress {
    protocol       = "ANY"
    description    = "Balancer ingress"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }
 
   ingress {
    protocol       = "TCP"
    description    = "Health"
	predefined_target = "loadbalancer_healthchecks"
  }

  egress {
    protocol       = "ANY"
    description    = "Balancer egress"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

#-----------Создание ВМ Nginx------------

# Nginx-1

resource "yandex_compute_instance" "nginx-1" {
  name = "nginx-1"
  hostname = "nginx-1"
  zone = "ru-central1-a"
  
  resources{
    cores = 2
    core_fraction = 5
    memory = 1
  }

  boot_disk{
    initialize_params {
      image_id = "fd8ecgtorub9r4609man"
      size = 10
    }
  }
  network_interface {
    subnet_id = "e9b12lvihp0do9drg3q3"
  }
  
  metadata = {
    user-data = "${file("./metadata.yml")}"
  }
}

# Nginx-2

resource "yandex_compute_instance" "nginx-2" {
  name = "nginx-2"
  hostname = "nginx-2"
  zone = "ru-central1-b"
  
  resources{
    cores = 2
    core_fraction = 5
    memory = 1
  }

  boot_disk{
    initialize_params {
      image_id = "fd8ecgtorub9r4609man"
      size = 10
    }
  }
  network_interface {
    subnet_id = "e2ljmrckk7r535aeg2f5"
  }
  
  metadata = {
    user-data = "${file("./metadata.yml")}"
  }
}

#-----------Создание Target group------------

resource "yandex_alb_target_group" "target-group" {
  name = "target-group"

  target {
    subnet_id = "e9b12lvihp0do9drg3q3"
    ip_address = yandex_compute_instance.nginx-1.network_interface.0.ip_address
  }

  target {
    subnet_id = "e2ljmrckk7r535aeg2f5"
    ip_address = yandex_compute_instance.nginx-2.network_interface.0.ip_address
  }
}

#-----------Создание Backend Group------------

resource "yandex_alb_backend_group" "backend-group" {
  name                     = "backend-group"
  http_backend {
    name                   = "backend"
    weight                 = 1
    port                   = 80
    target_group_ids       = [yandex_alb_target_group.target-group.id]
    load_balancing_config {
      panic_threshold      = 90
    }    
    healthcheck {
      timeout              = "10s"
      interval             = "2s"
      healthy_threshold    = 10
      unhealthy_threshold  = 15 
      http_healthcheck {
        path               = "/"
      }
    }
  }
}

#-----------Создание HTTP router------------

resource "yandex_alb_http_router" "http-router" {
  name          = "http-router"
  labels        = {
    tf-label    = "http-label-value"
    empty-label = ""
  }
}

resource "yandex_alb_virtual_host" "my-virtual-host" {
  name                    = "my-virtual-host"
  http_router_id          = yandex_alb_http_router.http-router.id
  route {
    name                  = "way"
    http_route {
      http_route_action {
        backend_group_id  = yandex_alb_backend_group.backend-group.id
        timeout           = "60s"
      }
    }
  }
}    

#-----------Создание L7-балансировщика------------

resource "yandex_alb_load_balancer" "balancer" {
  name        = "balancer"
  network_id  = "enp64t1jdhvoiv2i565h"
  security_group_ids = [yandex_vpc_security_group.balancer-security.id]

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = "e9bpn4ar1bfmppt8b66o" 
    }
  }

  listener {
    name = "listener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [ 80 ]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.http-router.id
      }
    }
  }
}


