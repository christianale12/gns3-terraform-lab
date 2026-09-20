# Proyecto del lab
resource "gns3_project" "lab" {
  name = var.project_name
}

# Variables base del lab
variable "gns3_host" {
  description = "URL base de la API REST del servidor GNS3."
  type        = string
  default     = "http://localhost:3080"
}

variable "project_name" {
  description = "Nombre del proyecto dentro de GNS3."
  type        = string
  default     = "enterprise_branch_lab"
}

# UUIDs de los templates registrados en GNS3
variable "mikrotik_template_id" {
  description = "UUID del template MikroTik CHR."
  type        = string
}

variable "vpcs_template_id" {
  description = "UUID del template VPCS."
  type        = string
}

# Arranca todos los nodos del proyecto
resource "gns3_start_all" "start_nodes" {
  project_id = gns3_project.lab.project_id
}

# Renombres de recursos: solo cambian el nombre en el estado, no recrean
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