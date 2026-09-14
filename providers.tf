terraform {
  required_version = ">= 1.0.0"
  required_providers {
    gns3 = {
      source  = "NetOpsChic/gns3"
      version = "~> 3.0"
    }
  }
}

provider "gns3" {
  host = "http://localhost:3080"
}
