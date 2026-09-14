# 1. Proyecto en GNS3
resource "gns3_project" "lab" {
  name = "enterprise_branch_lab"
}

# 2. Nodo NAT (Simula salida a internet)
resource "gns3_nat" "internet" {
  project_id = gns3_project.lab.project_id
  name       = "Internet-NAT"
}

# 3. Switch Core L2
resource "gns3_switch" "switch1" {
  project_id = gns3_project.lab.project_id
  name       = "Core-Switch"
}

# 4. Router MikroTik CHR
resource "gns3_template" "mikrotik1" {
  project_id  = gns3_project.lab.project_id
  name        = "MikroTik-Edge-Router"
  template_id = "a64bed07-cbe9-4e74-8645-366f9e9d472b"
  start       = true
}

# 5. PC de Oficina (VPCS nativo de GNS3)
resource "gns3_template" "office_pc" {
  project_id  = gns3_project.lab.project_id
  name        = "Office-PC"
  template_id = "19021f99-e36f-394d-b4a1-8aaa902ab9cc"
  start       = true
}

# --- CABLES / ENLACES ---

# NAT (Puerto 0) <---> MikroTik (Adaptador 0, Puerto 0 - WAN)
resource "gns3_link" "link_nat_mikrotik" {
  project_id     = gns3_project.lab.project_id
  node_a_id      = gns3_nat.internet.id
  node_a_adapter = 0
  node_a_port    = 0
  node_b_id      = gns3_template.mikrotik1.id
  node_b_adapter = 0
  node_b_port    = 0
}

# MikroTik (Adaptador 1, Puerto 0 - LAN) <---> Core-Switch (Puerto 0)
resource "gns3_link" "link_mikrotik_switch" {
  project_id     = gns3_project.lab.project_id
  node_a_id      = gns3_template.mikrotik1.id
  node_a_adapter = 1
  node_a_port    = 0
  node_b_id      = gns3_switch.switch1.id
  node_b_adapter = 0
  node_b_port    = 0
}

# Core-Switch (Puerto 1) <---> Office-PC (Puerto 0)
resource "gns3_link" "link_switch_pc" {
  project_id     = gns3_project.lab.project_id
  node_a_id      = gns3_switch.switch1.id
  node_a_adapter = 0
  node_a_port    = 1
  node_b_id      = gns3_template.office_pc.id
  node_b_adapter = 0
  node_b_port    = 0
}

# Forzar encendido general de nodos en el proyecto
resource "gns3_start_all" "start_nodes" {
  project_id = gns3_project.lab.project_id
}

# --- CORRECCIÓN AUTOMÁTICA DE SÍMBOLOS VÍA API ---

resource "null_resource" "fix_mikrotik_symbol" {
  depends_on = [gns3_template.mikrotik1]

  provisioner "local-exec" {
    command = <<EOT
      sleep 2
      curl -s -X PUT http://localhost:3080/v2/projects/${gns3_project.lab.project_id}/nodes/${gns3_template.mikrotik1.id} \
        -H "Content-Type: application/json" \
        -d '{"symbol": ":/symbols/router_firewall.svg"}'
    EOT
  }
}

resource "null_resource" "fix_switch_symbol" {
  depends_on = [gns3_switch.switch1]

  provisioner "local-exec" {
    command = <<EOT
      sleep 2
      curl -s -X PUT http://localhost:3080/v2/projects/${gns3_project.lab.project_id}/nodes/${gns3_switch.switch1.id} \
        -H "Content-Type: application/json" \
        -d '{"symbol": ":/symbols/ethernet_switch.svg"}'
    EOT
  }
}

resource "null_resource" "fix_nat_symbol" {
  depends_on = [gns3_nat.internet]

  provisioner "local-exec" {
    command = <<EOT
      sleep 2
      curl -s -X PUT http://localhost:3080/v2/projects/${gns3_project.lab.project_id}/nodes/${gns3_nat.internet.id} \
        -H "Content-Type: application/json" \
        -d '{"symbol": ":/symbols/nat.svg"}'
    EOT
  }
}

resource "null_resource" "fix_pc_symbol" {
  depends_on = [gns3_template.office_pc]

  provisioner "local-exec" {
    command = <<EOT
      sleep 2
      curl -s -X PUT http://localhost:3080/v2/projects/${gns3_project.lab.project_id}/nodes/${gns3_template.office_pc.id} \
        -H "Content-Type: application/json" \
        -d '{"symbol": ":/symbols/vpcs_guest.svg"}'
    EOT
  }
}
