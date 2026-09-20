# Icono por tipo de nodo
variable "device_icons" {
  description = "Ícono (symbol) de cada tipo de dispositivo."
  type        = map(string)
  default = {
    nat    = ":/symbols/nat.svg"
    router = ":/symbols/router.svg"
    switch = ":/symbols/ethernet_switch.svg"
    pc     = ":/symbols/vpcs_guest.svg"
  }
}

# GNS3 no aplica el icono del template al crear el nodo; se corrige por REST.
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