# Valores generados que podes leer con "terraform output".
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
    for k, s in gns3_template.switch : k => s.id
  }
}

output "mikrotik_ids" {
  description = "IDs de los routers MikroTik de borde."
  value = {
    for k, r in gns3_template.mikrotik : k => r.id
  }
}

output "pc_ids" {
  description = "IDs de todos los PCs."
  value = {
    for k, p in gns3_template.todas_las_pcs : k => p.id
  }
}