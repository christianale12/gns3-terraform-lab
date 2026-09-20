# ============================================================
# ÍCONOS
# La API de GNS3 no aplica el ícono de los templates al crear
# el nodo automáticamente. Este bloque recorre un mapa
# "clave -> {node_id, symbol}" y lo corrige con curl.
# El mapa NO se lista a mano: se arma solo a partir de los
# recursos for_each de cada tipo, así cada switch, router, PC
# o NAT recibe su ícono automáticamente. Agregar un nodo nuevo
# = no tocar nada acá. Los íconos viven en var.device_icons y
# las claves llevan prefijo para que nunca colisionen entre
# tipos.
# ============================================================

locals {
  icon_map = merge(
    {
      "nat" = { node_id = gns3_nat.internet.id, symbol = var.device_icons.nat }
    },
    {
      for k, node in gns3_template.switch : "switch/${k}" => {
        node_id = node.id
        symbol  = var.device_icons.switch
      }
    },
    {
      for k, node in gns3_template.mikrotik : "mikrotik/${k}" => {
        node_id = node.id
        symbol  = var.device_icons.router
      }
    },
    {
      for k, node in gns3_template.todas_las_pcs : "pc/${k}" => {
        node_id = node.id
        symbol  = var.device_icons.pc
      }
    }
  )
}

resource "null_resource" "fix_icons" {
  for_each = local.icon_map

  depends_on = [
    gns3_start_all.start_nodes
  ]

  triggers = {
    node_id = each.value.node_id
    symbol  = each.value.symbol
  }

  provisioner "local-exec" {
    command = <<-EOT
      sleep 2
      curl --fail --silent --show-error \
        --connect-timeout 2 \
        --max-time 5 \
        -X PUT \
        ${var.gns3_host}/v2/projects/${gns3_project.lab.project_id}/nodes/${each.value.node_id} \
        -H "Content-Type: application/json" \
        -d '{"symbol": "${each.value.symbol}"}' \
        -o /dev/null

      echo "Icono del nodo ${each.key} actualizado"
    EOT
  }
}
variable "device_icons" {
  description = "Ícono (symbol) de cada tipo de dispositivo. El código lo aplica solo, según el tipo de cada nodo. Cambiar un ícono acá alcanza para todos los nodos de ese tipo."
  type        = map(string)
  default = {
    nat    = ":/symbols/nat.svg"
    router = ":/symbols/router.svg"
    switch = ":/symbols/ethernet_switch.svg"
    pc     = ":/symbols/vpcs_guest.svg"
  }
}
