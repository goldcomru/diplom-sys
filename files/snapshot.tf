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

#-----------Создание snapshot------------

resource "yandex_compute_snapshot_schedule" "snapshot" {
  name = "snapshot"

  schedule_policy {
    expression = "0 1 * * *"
  }

  snapshot_count = 7
  snapshot_spec {
      description = "Daily snapshot"
 }

  retention_period = "168h"

  disk_ids = ["fhmqneusqdi871dn1pl6", 
             "fhm4v51dcmvuaj297kiq",
             "epdc5eq5ac6qugqfh2f5",
             "fhmkg2jfcp5vlvt3neoc",
             "fhmst4r6d8ram1hl2auc",
             "fhmo8hjaiokn86c25789"]
}