

# ============================================================
# 1. PROYECTO

resource "gns3_project" "lab" {
  name = var.project_name
}

# ============================================================
# TEMPLATES BASE DEL LAB
# Acá viven las variables y recursos de infraestructura:
# host de GNS3, nombre del proyecto y los template_id de
# MikroTik y VPCS. Terraform los encuentra desde cualquier
# archivo, no hace falta importarlos en main.tf.
# ============================================================

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

variable "mikrotik_template_id" {
  description = "UUID del template MikroTik CHR registrado en el servidor GNS3."
  type        = string
}

variable "vpcs_template_id" {
  description = "UUID del template VPCS registrado en el servidor GNS3."
  type        = string
}

resource "gns3_start_all" "start_nodes" {
  project_id = gns3_project.lab.project_id
}


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