# ============================================================
# OUTPUTS DEL LAB
# Con "terraform output" puedes leer estos valores sin mirar el estado.
# ============================================================

output "project_id" {
  description = "ID del proyecto GNS3."
  value       = gns3_project.lab.project_id
}

output "gns3_host" {
  description = "URL base de la API GNS3 usada."
  value       = var.gns3_host
}

output "nat_node_id" {
  description = "ID del nodo NAT (salida a internet)."
  value       = gns3_nat.internet.id
}

output "switch_ids" {
  description = "IDs de los switches de capa 2."
  value = {
    core1 = gns3_switch.switch1.id
    core2 = gns3_switch.switch2.id
  }
}

output "mikrotik_ids" {
  description = "IDs de los routers MikroTik de borde."
  value = {
    for k, router in gns3_template.mikrotik : k => router.id
  }
}

output "pc_ids" {
  description = "IDs de los PCs de oficina."
  value = {
    for k, pc in gns3_template.office_pc : k => pc.id
  }
}