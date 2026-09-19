# ============================================================
# VARIABLES DEL LAB
# Las variables evitan repetir valores hardcodeados y permiten
# reutilizar el código en entornos distintos.
# ============================================================

variable "gns3_host" {
  description = "URL base de la API REST del servidor GNS3."
  type        = string
  default     = "http://localhost:3080"
}

variable "project_name" {
  description = "Nombre del proyecto dentro de GNS3."
  type        = string
  default     = "enterprise_branch_lab"
}

variable "mikrotik_template_id" {
  description = "UUID del template MikroTik CHR registrado en el servidor GNS3."
  type        = string
}

variable "vpcs_template_id" {
  description = "UUID del template VPCS registrado en el servidor GNS3."
  type        = string
}

variable "mikrotik_routers" {
  description = "Routers MikroTik de borde. Cada entrada genera un nodo; agregar uno aqui lo crea."
  type = map(object({
    name     = string
    x        = number
    y        = number
    wan_port = number
  }))
  default = {
    edge1 = { name = "MikroTik-Edge-Router1", x = 0, y = 0, wan_port = 1 }
    edge2 = { name = "MikroTik-Edge-Router2", x = 150, y = 0, wan_port = 2 }
    edge3 = { name = "MikroTik-Edge-Router3", x = 300, y = 0, wan_port = 3 }
    edge4 = { name = "MikroTik-Edge-Router4", x = 450, y = 0, wan_port = 4 }
  }
}

variable "office_pcs" {
  description = "PCs de oficina (VPCS). Cada entrada genera un nodo."
  type = map(object({
    wan_port = number
    name     = string
    x        = number
    y        = number
  }))
  default = {
    pc1 = { name = "Office-PC1", x = -100, y = 200, wan_port = 1 }
    pc2 = { name = "Office-PC2", x = 0, y = 200, wan_port = 2 }

  }
}
variable "plantaAlta_pcs" {
  description = "PCs planta alta(VPCS). Cada entrada genera un nodo."
  type = map(object({
    wan_port = number
    name     = string
    x        = number
    y        = number
  }))
  default = {
    "alta-1" = { name = "PlantaAlta-PC1", x = 100, y = 200, wan_port = 1 }
    "alta-2" = { name = "PlantaAlta-PC2", x = 200, y = 200, wan_port = 2 }

  }
}
variable "plantaBaja_pcs" {
  description = "PCs Planta Baja (VPCS). Cada entrada genera un nodo."
  type = map(object({
    wan_port = number
    name     = string
    x        = number
    y        = number
  }))
  default = {
    "baja-1" = { name = "PlantaBaja-PC1", x = 300, y = 200, wan_port = 1 }
    "baja-2" = { name = "PlantaBaja-PC2", x = 400, y = 200, wan_port = 2 }

  }
}
variable "deposito_pcs" {
  description = "PCs deposito (VPCS). Cada entrada genera un nodo."
  type = map(object({
    wan_port = number
    name     = string
    x        = number
    y        = number
  }))
  default = {
    "depo-1" = { name = "Deposito-PC1", x = 500, y = 200, wan_port = 1 }
    "depo-2" = { name = "Deposito-PC2", x = 600, y = 200, wan_port = 2 }

  }
}