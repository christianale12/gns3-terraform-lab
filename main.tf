# ============================================================
# GNS3 ENTERPRISE BRANCH LAB
# Terraform + GNS3
#
# Cómo está organizado este archivo:
#   1. Proyecto   -> contenedor del lab en GNS3
#   2. Nodos      -> NAT, switches, routers MikroTik y PCs VPCS
#   3. Enlaces    -> los cables que conectan los nodos
#   4. Auto-start -> enciende todos los nodos al aplicar
#   5. Íconos     -> corrige los íconos por API REST
#   6. moved      -> renombres de recursos sin perder el estado
# ============================================================


# ============================================================
# 1. PROYECTO
# Todo nodo y enlace del lab vive adentro de este proyecto.
# El project_id se referencia en cada recurso con
# gns3_project.lab.project_id.
# ============================================================

resource "gns3_project" "lab" {
  name = var.project_name
}


# ============================================================
# 2. NODOS DE RED
# ============================================================

# ------------------------------------------------------------
# 2.1 NAT - simula la salida a internet.
# Es único y sin repetición: todo el lab sale por acá.
# ------------------------------------------------------------

resource "gns3_nat" "internet" {
  project_id = gns3_project.lab.project_id
  name       = "Internet-NAT"

  x = 100
  y = -200
}

# ------------------------------------------------------------
# 2.2 SWITCHES de capa 2.
# Se declaran uno por uno (sin for_each) porque cada switch
# tiene rol y posición propios en el lienzo.
#   - switch1: PCs de oficina
#   - switch2: uplink NAT/WAN (reparte red a todos los routers)
#   - switch3: PCs planta alta + router edge2
#   - switch4: PCs planta baja + router edge3
#   - switch5: PCs depósito + router edge4
# ------------------------------------------------------------

resource "gns3_switch" "switch1" {
  project_id = gns3_project.lab.project_id
  name       = "Core-Switch1"

  x = 0
  y = 100
}

resource "gns3_switch" "switch2" {
  project_id = gns3_project.lab.project_id
  name       = "Core-Switch2"

  x = 150
  y = -100
}

resource "gns3_switch" "switch3" {
  project_id = gns3_project.lab.project_id
  name       = "Core-Switch3"

  x = 150
  y = 100
}

resource "gns3_switch" "switch4" {
  project_id = gns3_project.lab.project_id
  name       = "Core-Switch4"

  x = 300
  y = 100
}

resource "gns3_switch" "switch5" {
  project_id = gns3_project.lab.project_id
  name       = "Core-Switch5"

  x = 450
  y = 100
}

# ------------------------------------------------------------
# 2.3 ROUTERS MIKROTIK CHR - un solo bloque crea TODOS.
# for_each recorre el mapa var.mikrotik_routers (variables.tf).
# Agregar un router = agregar una entrada al mapa, sin tocar
# este archivo.
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
# 2.4 PCs VPCS - un solo bloque crea TODOS los PCs.
# for_each recorre var.pcs (variables.tf), que ya trae la clave
# "switch" para saber a qué switch pertenece cada PC.
# ------------------------------------------------------------

resource "gns3_template" "todas_las_pcs" {
  for_each    = var.pcs
  project_id  = gns3_project.lab.project_id
  name        = each.value.name
  template_id = var.vpcs_template_id

  start = true

  x = each.value.x
  y = each.value.y
}


# ============================================================
# 3. ENLACES (los cables)
# Cada enlace tiene dos extremos:
#   node_a_* = extremo A con su id, adapter y puerto
#   node_b_* = extremo B con su id, adapter y puerto
# El puerto del switch va en node_a_port (o node_b_port).
# ============================================================

# ------------------------------------------------------------
# 3.1 NAT -> SWITCH2 (uplink a internet)
# ------------------------------------------------------------

resource "gns3_link" "link_nat_switch" {
  project_id = gns3_project.lab.project_id

  node_a_id      = gns3_nat.internet.id
  node_a_adapter = 0
  node_a_port    = 0

  node_b_id      = gns3_switch.switch2.id
  node_b_adapter = 0
  node_b_port    = 0
}

# ------------------------------------------------------------
# 3.2 ROUTER -> SU SWITCH (un bloque los genera a todos)
# El mapa mikrotik_to_switch le dice a cada router a qué switch
# se enlaza y en qué adapter. node_a es el router y node_b el
# switch.
# ------------------------------------------------------------

locals {
  mikrotik_to_switch = {
    edge1 = { switch_id = gns3_switch.switch1.id, adapter = 1 }
    edge2 = { switch_id = gns3_switch.switch3.id, adapter = 4 }
    edge3 = { switch_id = gns3_switch.switch4.id, adapter = 4 }
    edge4 = { switch_id = gns3_switch.switch5.id, adapter = 4 }
  }
}

resource "gns3_link" "mikrotik_to_switch" {
  for_each = local.mikrotik_to_switch

  project_id = gns3_project.lab.project_id

  node_a_id      = gns3_template.mikrotik[each.key].id
  node_a_adapter = each.value.adapter
  node_a_port    = 0

  node_b_id      = each.value.switch_id
  node_b_adapter = 0
  node_b_port    = 0
}

# ------------------------------------------------------------
# 3.3 CADENA router <-> router
# Conecta router N con router N+1 (adap2 p0 -> adap1 p0).
# count genera length(routers) - 1 enlaces, es decir los pares
# consecutivos de la lista.
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
# 3.4 SWITCH2 -> TODOS los routers (uplink WAN)
# switch2 reparte la salida a internet a todos los routers.
# El puerto de switch2 es each.value.wan_port (vive en el mapa).
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
# 3.5 SWITCH -> CADA PC (un bloque los genera a todos)
# var.pcs ya trae la clave "switch" (ej. "switch3") en cada PC.
# switch_ids traduce esa clave al id real del recurso, y
# pc_switch_map deja listo un mapa con TODOS los datos que
# necesita el enlace: el switch y el puerto wan de cada PC.
# ------------------------------------------------------------

locals {
  switch_ids = {
    switch1 = gns3_switch.switch1.id
    switch2 = gns3_switch.switch2.id
    switch3 = gns3_switch.switch3.id
    switch4 = gns3_switch.switch4.id
    switch5 = gns3_switch.switch5.id
  }

  pc_switch_map = {
    for k, pc in var.pcs : k => merge(pc, { switch = local.switch_ids[pc.switch] })
  }
}

resource "gns3_link" "pc_to_switch" {
  for_each = local.pc_switch_map

  project_id = gns3_project.lab.project_id

  # Extremo A: el switch (id salido del mapa enriquecido)
  node_a_id      = each.value.switch
  node_a_adapter = 0
  node_a_port    = each.value.wan_port

  # Extremo B: el PC
  node_b_id      = gns3_template.todas_las_pcs[each.key].id
  node_b_adapter = 0
  node_b_port    = 0
}


# ============================================================
# 4. AUTO-START
# Enciende todos los nodos del proyecto al aplicar.
# ============================================================

resource "gns3_start_all" "start_nodes" {
  project_id = gns3_project.lab.project_id
}


# ============================================================
# 5. ÍCONOS
# La API de GNS3 no aplica el ícono de los templates al crear
# el nodo automáticamente. Este bloque recorre un mapa
# "clave -> {node_id, symbol}" y lo corrige con curl.
# MikroTik NO se toca: su template ya trae el ícono correcto.
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


# ============================================================
# 6. RENOMBRES (moved)
# Cuando se cambia el nombre de un recurso, Terraform lo
# destruiría y recrearía. Bloques `moved` le dicen que solo es
# un cambio de nombre, conservando el estado y los recursos.
# ============================================================

moved {
  from = gns3_template.office_pc
  to   = gns3_template.todas_las_pcs
}

moved {
  from = gns3_link.link_nat_mikrotik
  to   = gns3_link.link_nat_switch
}

moved {
  from = gns3_link.pc_to_Swittch
  to   = gns3_link.pc_to_switch
}