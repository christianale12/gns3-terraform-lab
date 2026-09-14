# ============================================================
# GNS3 ENTERPRISE BRANCH LAB
# Terraform + GNS3
# ============================================================


# ------------------------------------------------------------
# 1. PROYECTO
# ------------------------------------------------------------

resource "gns3_project" "lab" {
  name = "enterprise_branch_lab"
}


# ------------------------------------------------------------
# 2. NAT - SALIDA A INTERNET
# ------------------------------------------------------------

resource "gns3_nat" "internet" {
  project_id = gns3_project.lab.project_id
  name       = "Internet-NAT"

  x = -300
  y = 0
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
# 4. ROUTER MIKROTIK CHR
# ------------------------------------------------------------

resource "gns3_template" "mikrotik1" {
  project_id  = gns3_project.lab.project_id
  name        = "MikroTik-Edge-Router"
  template_id = "a64bed07-cbe9-4e74-8645-366f9e9d472b"

  start = true

  x = 0
  y = 0
}

resource "gns3_template" "mikrotik2" {
  project_id  = gns3_project.lab.project_id
  name        = "MikroTik-Edge-Router"
  template_id = "a64bed07-cbe9-4e74-8645-366f9e9d472b"

  start = true

  x = 250
  y = 0
}

resource "gns3_template" "mikrotik3" {
  project_id  = gns3_project.lab.project_id
  name        = "MikroTik-Edge-Router"
  template_id = "a64bed07-cbe9-4e74-8645-366f9e9d472b"

  start = true

  x = 500
  y = 0
}

# ------------------------------------------------------------
# 5. PC DE OFICINA - VPCS
# ------------------------------------------------------------

resource "gns3_template" "office_pc" {
  project_id  = gns3_project.lab.project_id
  name        = "Office-PC"
  template_id = "19021f99-e36f-394d-b4a1-8aaa902ab9cc"

  start = true

  x = -100
  y = 200
}

resource "gns3_template" "office_pc2" {
  project_id  = gns3_project.lab.project_id
  name        = "Office-PC2"
  template_id = "19021f99-e36f-394d-b4a1-8aaa902ab9cc"

  start = true

  x = 100
  y = 200
}


# ============================================================
# ENLACES
# ============================================================


# ------------------------------------------------------------
# NAT <-> MIKROTIK
# ------------------------------------------------------------

resource "gns3_link" "link_nat_mikrotik" {
  project_id = gns3_project.lab.project_id

  node_a_id      = gns3_nat.internet.id
  node_a_adapter = 0
  node_a_port    = 0

  node_b_id      = gns3_template.mikrotik1.id
  node_b_adapter = 0
  node_b_port    = 0
}


# ------------------------------------------------------------
# MIKROTIK <-> SWITCH
# ------------------------------------------------------------

resource "gns3_link" "link_mikrotik_switch" {
  project_id = gns3_project.lab.project_id

  node_a_id      = gns3_template.mikrotik1.id
  node_a_adapter = 1
  node_a_port    = 0

  node_b_id      = gns3_switch.switch1.id
  node_b_adapter = 0
  node_b_port    = 0
}


# ------------------------------------------------------------
# SWITCH <-> PC
# ------------------------------------------------------------

resource "gns3_link" "link_switch_pc1" {
  project_id = gns3_project.lab.project_id

  node_a_id      = gns3_switch.switch1.id
  node_a_adapter = 0
  node_a_port    = 1

  node_b_id      = gns3_template.office_pc.id
  node_b_adapter = 0
  node_b_port    = 0
}

# ------------------------------------------------------------
# SWITCH <-> PC2
# ------------------------------------------------------------

resource "gns3_link" "link_switch_pc2" {
  project_id = gns3_project.lab.project_id

  node_a_id      = gns3_switch.switch1.id
  node_a_adapter = 0
  node_a_port    = 2

  node_b_id      = gns3_template.office_pc2.id
  node_b_adapter = 0
  node_b_port    = 0
}


# ------------------------------------------------------------
# MIKROTIK1 <-> mikrotik2
# ------------------------------------------------------------

resource "gns3_link" "link_mikrotik1_mikrotik2" {
  project_id = gns3_project.lab.project_id

  node_a_id      = gns3_template.mikrotik1.id
  node_a_adapter = 2
  node_a_port    = 0

  node_b_id      = gns3_template.mikrotik2.id
  node_b_adapter = 1
  node_b_port    = 0
}

# ------------------------------------------------------------
# MIKROTIK2 <-> mikrotik3
# ------------------------------------------------------------

resource "gns3_link" "link_mikrotik2_mikrotik3" {
  project_id = gns3_project.lab.project_id

  node_a_id      = gns3_template.mikrotik2.id
  node_a_adapter = 2
  node_a_port    = 0

  node_b_id      = gns3_template.mikrotik3.id
  node_b_adapter = 1
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
        http://localhost:3080/v2/projects/${gns3_project.lab.project_id}/nodes/${gns3_nat.internet.id} \
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
    node_id = gns3_switch.switch1.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl --fail --silent --show-error \
        --connect-timeout 2 \
        --max-time 5 \
        -X PUT \
        http://localhost:3080/v2/projects/${gns3_project.lab.project_id}/nodes/${gns3_switch.switch1.id} \
        -H "Content-Type: application/json" \
        -d '{"symbol": ":/symbols/ethernet_switch.svg"}' \
        -o /dev/null

      echo "Switch icon actualizado correctamente"
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
    node_id = gns3_template.office_pc.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl --fail --silent --show-error \
        --connect-timeout 2 \
        --max-time 5 \
        -X PUT \
        http://localhost:3080/v2/projects/${gns3_project.lab.project_id}/nodes/${gns3_template.office_pc.id} \
        -H "Content-Type: application/json" \
        -d '{"symbol": ":/symbols/vpcs_guest.svg"}' \
        -o /dev/null

      echo "PC icon actualizado correctamente"
    EOT
  }
}
