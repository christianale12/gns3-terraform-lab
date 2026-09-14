#!/bin/bash

set -e

echo "========================================"
echo " GNS3 - Corrección de símbolos"
echo "========================================"

# Obtener IDs desde Terraform
PROJECT_ID=$(terraform state show gns3_project.lab | awk -F'"' '/project_id =/ {print $2}')
NAT_ID=$(terraform state show gns3_nat.internet | awk -F'"' '/id         =/ {print $2}')
SWITCH_ID=$(terraform state show gns3_switch.switch1 | awk -F'"' '/id         =/ {print $2}')
PC_ID=$(terraform state show gns3_template.office_pc | awk -F'"' '/id          =/ {print $2}')

echo "Proyecto : $PROJECT_ID"
echo "NAT      : $NAT_ID"
echo "Switch   : $SWITCH_ID"
echo "PC       : $PC_ID"
echo

echo "[1/3] Configurando icono NAT..."

curl -s -X PUT \
  "http://localhost:3080/v2/projects/$PROJECT_ID/nodes/$NAT_ID" \
  -H "Content-Type: application/json" \
  -d '{"symbol": ":/symbols/nat.svg"}'

echo
echo "NAT OK"

echo
echo "[2/3] Configurando icono Switch..."

curl -s -X PUT \
  "http://localhost:3080/v2/projects/$PROJECT_ID/nodes/$SWITCH_ID" \
  -H "Content-Type: application/json" \
  -d '{"symbol": ":/symbols/ethernet_switch.svg"}'

echo
echo "Switch OK"

echo
echo "[3/3] Configurando icono PC..."

curl -s -X PUT \
  "http://localhost:3080/v2/projects/$PROJECT_ID/nodes/$PC_ID" \
  -H "Content-Type: application/json" \
  -d '{"symbol": ":/symbols/vpcs_guest.svg"}'

echo
echo "PC OK"

echo
echo "========================================"
echo " Símbolos configurados correctamente"
echo "========================================"
