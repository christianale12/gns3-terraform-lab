# ============================================================
# GNS3 ENTERPRISE BRANCH LAB
# Terraform + GNS3
# ============================================================


# ------------------------------------------------------------
# 1. PROYECTO
# ------------------------------------------------------------

resource "gns3_project" "lab" {
  name = var.project_name
}


# ------------------------------------------------------------
# 2. NAT - SALIDA A INTERNET
# ------------------------------------------------------------

resource "gns3_nat" "internet" {
  project_id = gns3_project.lab.project_id
  name       = "Internet-NAT"

  x = 100
  y = -200
}


# ------------------------------------------------------------
# 3. SWITCH CORE L2
# ------------------------------------------------------------

resource "gns3_switch" "switch1" {
  project_id = gns3_project.lab.project_id
  name       = "Core-Switch1"

  x = 0
  y = 100
}

# ------------------------------------------------------------
#  SWITCH CORE L2 a NAT
# ------------------------------------------------------------

resource "gns3_switch" "switch2" {
  project_id = gns3_project.lab.project_id
  name       = "Core-Switch2"

  x = 150
  y = -100
}
# ------------------------------------------------------------
#  SWITCH3
# ------------------------------------------------------------

resource "gns3_switch" "switch3" {
  project_id = gns3_project.lab.project_id
  name       = "Core-Switch3"

  x = 150
  y = 100
}
# ------------------------------------------------------------
#  SWITCH4
# ------------------------------------------------------------

resource "gns3_switch" "switch4" {
  project_id = gns3_project.lab.project_id
  name       = "Core-Switch4"

  x = 300
  y = 100
}
# ------------------------------------------------------------
#  SWITCH5
# ------------------------------------------------------------

resource "gns3_switch" "switch5" {
  project_id = gns3_project.lab.project_id
  name       = "Core-Switch5"

  x = 450
  y = 100
}
# ------------------------------------------------------------
# 4. ROUTER MIKROTIK CHR
# for_each: UN solo bloque genera TODOS los routers.
# La lista vive en var.mikrotik_routers (variables.tf).
# ------------------------------------------------------------

resource "gns3_template" "mikrotik" {
  for_each    = var.mikrotik_routers
  project_id  = gns3_project.lab.project_id
  name        = each.value.name
  template_id = var.mikrotik_template_id

  start = true

  x = each.value.x
  y = each.value.y
}

# ------------------------------------------------------------
# 5. PCs - VPCS (oficina + plantas + deposito)
# for_each: UN solo bloque genera TODOS los PCs.
# merge() une los mapas office_pcs + plantaAlta_pcs + plantaBaja_pcs
# + deposito_pcs.
# Ojo: las claves de todos los mapas deben ser UNICAS entre sí
# (por eso prefijos "alta-", "baja-", "depo-").
# ------------------------------------------------------------

resource "gns3_template" "todas_las_pcs" {
  for_each    = merge(var.office_pcs, var.plantaAlta_pcs, var.plantaBaja_pcs, var.deposito_pcs)
  project_id  = gns3_project.lab.project_id
  name        = each.value.name
  template_id = var.vpcs_template_id

  start = true

  x = each.value.x
  y = each.value.y
}


# ============================================================
# ENLACES
# ============================================================


# ------------------------------------------------------------
# NAT <-> SWITCH2
# ------------------------------------------------------------

resource "gns3_link" "link_nat_mikrotik" {
  project_id = gns3_project.lab.project_id

  node_a_id      = gns3_nat.internet.id
  node_a_adapter = 0
  node_a_port    = 0

  node_b_id      = gns3_switch.switch2.id
  node_b_adapter = 0
  node_b_port    = 0

}


# ------------------------------------------------------------
# MIKROTIK1 <-> SWITCH
# ------------------------------------------------------------

resource "gns3_link" "link_mikrotik_switch" {
  project_id = gns3_project.lab.project_id

  node_a_id      = gns3_template.mikrotik["edge1"].id
  node_a_adapter = 1
  node_a_port    = 0

  node_b_id      = gns3_switch.switch1.id
  node_b_adapter = 0
  node_b_port    = 0
}


# ------------------------------------------------------------
# MIKROTIK2 <-> SWITCH3
# ------------------------------------------------------------

resource "gns3_link" "link_mikrotik2_switch2" {
  project_id = gns3_project.lab.project_id

  node_a_id      = gns3_template.mikrotik["edge2"].id
  node_a_adapter = 4
  node_a_port    = 0

  node_b_id      = gns3_switch.switch3.id
  node_b_adapter = 0
  node_b_port    = 0
}






# ------------------------------------------------------------
# CADENA router <-> router (un solo bloque genera todos los pares)
# Regla física: router N se une con router N+1 (adap2 p0 -> adap1 p0)
# ------------------------------------------------------------

locals {
  router_chain = tolist(keys(var.mikrotik_routers))
}

resource "gns3_link" "router_to_router" {
  count      = length(local.router_chain) - 1
  project_id = gns3_project.lab.project_id

  node_a_id      = gns3_template.mikrotik[local.router_chain[count.index]].id
  node_a_adapter = 2
  node_a_port    = 0

  node_b_id      = gns3_template.mikrotik[local.router_chain[count.index + 1]].id
  node_b_adapter = 1
  node_b_port    = 0
}

# ------------------------------------------------------------
# SWITCH2 <-> TODOS los mikrotik (un bloque los genera a todos)
# ------------------------------------------------------------

resource "gns3_link" "switch_to_router" {
  for_each = var.mikrotik_routers

  project_id = gns3_project.lab.project_id

  node_a_id      = gns3_switch.switch2.id
  node_a_adapter = 0
  node_a_port    = each.value.wan_port

  node_b_id      = gns3_template.mikrotik[each.key].id
  node_b_adapter = 0
  node_b_port    = 0
}
# ------------------------------------------------------------
# SWITCH1 <-> TODOS los mikrotik (un bloque los genera a todos)
# ------------------------------------------------------------

resource "gns3_link" "switch_to_pc" {
  for_each = var.office_pcs

  project_id = gns3_project.lab.project_id

  node_a_id      = gns3_switch.switch1.id
  node_a_adapter = 0
  node_a_port    = each.value.wan_port

  node_b_id      = gns3_template.todas_las_pcs[each.key].id
  node_b_adapter = 0
  node_b_port    = 0
}

# ------------------------------------------------------------
# ARRANCAR TODOS LOS NODOS
# ------------------------------------------------------------

resource "gns3_start_all" "start_nodes" {
  project_id = gns3_project.lab.project_id
}


# ============================================================
# CORRECCIÓN AUTOMÁTICA DE ÍCONOS
# ============================================================
#
# MikroTik NO se modifica: su template ya trae el icono correcto.
# Para el resto, UN SOLO bloque recorre un mapa "nodo -> simbolo"
# y aplica cada icono con un curl. Agregar un nodo (PC, switch...)
# no requiere tocar este código.
# ============================================================

locals {
  icon_map = merge(
    {
      "nat"     = { node_id = gns3_nat.internet.id, symbol = ":/symbols/nat.svg" }
      "switch1" = { node_id = gns3_switch.switch1.id, symbol = ":/symbols/ethernet_switch.svg" }
      "switch2" = { node_id = gns3_switch.switch2.id, symbol = ":/symbols/ethernet_switch.svg" }
      "switch3" = { node_id = gns3_switch.switch3.id, symbol = ":/symbols/ethernet_switch.svg" }
      "switch4" = { node_id = gns3_switch.switch4.id, symbol = ":/symbols/ethernet_switch.svg" }
      "switch5" = { node_id = gns3_switch.switch5.id, symbol = ":/symbols/ethernet_switch.svg" }
    },
    { for k, pc in gns3_template.todas_las_pcs : k => { node_id = pc.id, symbol = ":/symbols/vpcs_guest.svg" } }
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
