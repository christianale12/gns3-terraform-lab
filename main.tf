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
  name       = "Core-Switch"

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
# 5. PC DE OFICINA - VPCS
# for_each: UN solo bloque genera TODOS los PCs.
# La lista vive en var.office_pcs (variables.tf).
# ------------------------------------------------------------

resource "gns3_template" "office_pc" {
  for_each    = var.office_pcs
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

  node_b_id      = gns3_template.office_pc[each.key].id
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
# MikroTik NO se modifica.
# Su template ya proporciona el icono correcto.
#
# Los otros tres nodos se corrigen mediante la API de GNS3.
# Los node_id funcionan como trigger para que, después de un
# destroy/apply, los nuevos nodos vuelvan a recibir su símbolo.
# ============================================================


# ------------------------------------------------------------
# NAT
# ------------------------------------------------------------

resource "null_resource" "fix_nat_symbol" {

  depends_on = [
    gns3_start_all.start_nodes
  ]

  triggers = {
    node_id = gns3_nat.internet.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      sleep 3

      curl --fail --silent --show-error \
        --connect-timeout 2 \
        --max-time 5 \
        -X PUT \
        ${var.gns3_host}/v2/projects/${gns3_project.lab.project_id}/nodes/${gns3_nat.internet.id} \
        -H "Content-Type: application/json" \
        -d '{"symbol": ":/symbols/nat.svg"}' \
        -o /dev/null

      echo "NAT icon actualizado correctamente"
    EOT
  }
}


# ------------------------------------------------------------
# SWITCH
# ------------------------------------------------------------

resource "null_resource" "fix_switch_symbol" {

  depends_on = [
    gns3_start_all.start_nodes,
    null_resource.fix_nat_symbol
  ]

  triggers = {
    switch1_id = gns3_switch.switch1.id
    switch2_id = gns3_switch.switch2.id
  }

  provisioner "local-exec" {
    command = <<-EOT

    curl --fail --silent --show-error \
      --connect-timeout 2 \
      --max-time 5 \
      -X PUT \
      ${var.gns3_host}/v2/projects/${gns3_project.lab.project_id}/nodes/${gns3_switch.switch1.id} \
      -H "Content-Type: application/json" \
      -d '{"symbol": ":/symbols/ethernet_switch.svg"}' \
      -o /dev/null

    echo "Switch1 icon actualizado correctamente"

    curl --fail --silent --show-error \
      --connect-timeout 2 \
      --max-time 5 \
      -X PUT \
      ${var.gns3_host}/v2/projects/${gns3_project.lab.project_id}/nodes/${gns3_switch.switch2.id} \
      -H "Content-Type: application/json" \
      -d '{"symbol": ":/symbols/ethernet_switch.svg"}' \
      -o /dev/null

    echo "Switch2 icon actualizado correctamente"

  EOT
  }
}

# ------------------------------------------------------------
# PC
# ------------------------------------------------------------

resource "null_resource" "fix_pc_symbol" {

  depends_on = [
    gns3_start_all.start_nodes,
    null_resource.fix_switch_symbol
  ]

  triggers = {
    node_id  = gns3_template.office_pc["pc1"].id
    node2_id = gns3_template.office_pc["pc2"].id
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl --fail --silent --show-error \
        --connect-timeout 2 \
        --max-time 5 \
        -X PUT \
        ${var.gns3_host}/v2/projects/${gns3_project.lab.project_id}/nodes/${gns3_template.office_pc["pc1"].id} \
        -H "Content-Type: application/json" \
        -d '{"symbol": ":/symbols/vpcs_guest.svg"}' \
        -o /dev/null

      echo "PC1 icon actualizado correctamente"

      curl --fail --silent --show-error \
        --connect-timeout 2 \
        --max-time 5 \
        -X PUT \
        ${var.gns3_host}/v2/projects/${gns3_project.lab.project_id}/nodes/${gns3_template.office_pc["pc2"].id} \
        -H "Content-Type: application/json" \
        -d '{"symbol": ":/symbols/vpcs_guest.svg"}' \
        -o /dev/null

      echo "PC2 icon actualizado correctamente"
    EOT
  }
}
