locals {
  prefix = "nocobase-${var.env}"

  tags = {
    environment = var.env
    project     = "nocobase"
    managed_by  = "terraform"
  }
}
