# NODOS

resource "gns3_nat" "internet" {
  project_id = gns3_project.lab.project_id
  name       = "Internet-NAT"

  x = 200
  y = -200
}

# Switches de capa 2 (template "Ethernet switch")
data "gns3_template_id" "switch" {
  name = "Ethernet switch"
}

resource "gns3_template" "switch" {
  for_each    = var.switch_all
  project_id  = gns3_project.lab.project_id
  name        = each.value.name
  template_id = data.gns3_template_id.switch.template_id

  start = true

  x = each.value.x
  y = each.value.y
}

# Routers MikroTik CHR
resource "gns3_template" "mikrotik" {
  for_each    = var.mikrotik_routers
  project_id  = gns3_project.lab.project_id
  name        = each.value.name
  template_id = var.mikrotik_template_id

  start = true

  x = each.value.x
  y = each.value.y
}

# PCs VPCS
resource "gns3_template" "todas_las_pcs" {
  for_each    = var.pcs
  project_id  = gns3_project.lab.project_id
  name        = each.value.name
  template_id = var.vpcs_template_id

  start = true

  x = each.value.x
  y = each.value.y
}

# ENLACES

# NAT -> switch uplink
resource "gns3_link" "link_nat_switch" {
  project_id = gns3_project.lab.project_id

  node_a_id      = gns3_nat.internet.id
  node_a_adapter = 0
  node_a_port    = 0

  node_b_id      = gns3_template.switch[var.uplink_switch].id
  node_b_adapter = 0
  node_b_port    = 0
}

# Router -> su switch (cada edge trae "switch" y "adapter" en su mapa)
locals {
  switch_ids = {
    for k, s in gns3_template.switch : k => s.id
  }

  mikrotik_to_switch = {
    for k, r in var.mikrotik_routers : k => {
      switch_id = local.switch_ids[r.switch]
      adapter   = r.adapter
    }
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

# Cadena router <-> router
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

# Switch uplink -> todos los routers (reparte internet)
resource "gns3_link" "switch_to_router" {
  for_each = var.mikrotik_routers

  project_id = gns3_project.lab.project_id

  node_a_id      = gns3_template.switch[var.uplink_switch].id
  node_a_adapter = 0
  node_a_port    = each.value.wan_port

  node_b_id      = gns3_template.mikrotik[each.key].id
  node_b_adapter = 0
  node_b_port    = 0
}

# Switch -> cada PC (el PC dice a que switch va en "switch")
locals {
  pc_switch_map = {
    for k, pc in var.pcs : k => merge(pc, { switch = local.switch_ids[pc.switch] })
  }
}

resource "gns3_link" "pc_to_switch" {
  for_each = local.pc_switch_map

  project_id = gns3_project.lab.project_id

  node_a_id      = each.value.switch
  node_a_adapter = 0
  node_a_port    = each.value.wan_port

  node_b_id      = gns3_template.todas_las_pcs[each.key].id
  node_b_adapter = 0
  node_b_port    = 0
}