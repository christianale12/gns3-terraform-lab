
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

variable "pcs" {
  description = "PCs VPCS. Una sola variable agrupa todas (oficina, plantas y depósito). Cada entrada genera un nodo y declara a qué switch se conecta con la clave 'switch'."
  type = map(object({
    name     = string
    x        = number
    y        = number
    wan_port = number
    switch   = string
  }))
  default = {
    pc1      = { name = "Office-PC1", x = -100, y = 200, wan_port = 1, switch = "switch1" }
    pc2      = { name = "Office-PC2", x = 0, y = 200, wan_port = 2, switch = "switch1" }
    "alta-1" = { name = "PlantaAlta-PC1", x = 100, y = 200, wan_port = 1, switch = "switch3" }
    "alta-2" = { name = "PlantaAlta-PC2", x = 200, y = 200, wan_port = 2, switch = "switch3" }
    "baja-1" = { name = "PlantaBaja-PC1", x = 300, y = 200, wan_port = 1, switch = "switch4" }
    "baja-2" = { name = "PlantaBaja-PC2", x = 400, y = 200, wan_port = 2, switch = "switch4" }
    "depo-1" = { name = "Deposito-PC1", x = 500, y = 200, wan_port = 1, switch = "switch5" }
    "depo-2" = { name = "Deposito-PC2", x = 600, y = 200, wan_port = 2, switch = "switch5" }
  }
}

variable "switch_all" {
  description = "Switches de capa 2. Cada entrada genera un nodo; agregar uno aqui lo crea. La clave debe coincidir con el campo 'switch' de cada PC y con los enlaces."
  type = map(object({
    name     = string
    x        = number
    y        = number
    wan_port = number
  }))
  default = {
    switch1 = { name = "Core-Switch1", x = 0, y = 100, wan_port = 1 }
    switch2 = { name = "Core-Switch2", x = 200, y = -100, wan_port = 2 }
    switch3 = { name = "Core-Switch3", x = 150, y = 100, wan_port = 3 }
    switch4 = { name = "Core-Switch4", x = 300, y = 100, wan_port = 4 }
    switch5 = { name = "Core-Switch5", x = 450, y = 100, wan_port = 4 }
  }
}
