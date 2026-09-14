Enterprise Branch Lab (GNS3 + Terraform)
Laboratorio de red para sucursales empresariales desplegado y gestionado de forma automatizada mediante Infraestructura como Código (IaC) con Terraform y GNS3.

Topology Overview
La topología simula una sucursal conectada a internet y consta de los siguientes componentes:

Internet-NAT: Nodo de GNS3 que simula la salida a internet.

MikroTik-Edge-Router: Router de borde ejecutando MikroTik CHR.

Core-Switch: Switch de Capa 2 para la segmentación interna.

Office-PC: Equipo terminal ligero basado en VPCS.

Características
Despliegue declarativo: Creación de proyectos, nodos, adaptadores y enlaces de red mediante Terraform (NetOpsChic/gns3).

Auto-start: Encendido automático de todos los dispositivos al aplicar el plan.

Corrección visual por API: Integración con la API REST de GNS3 (http://localhost:3080) a través de null_resource y local-exec para inyectar y corregir automáticamente los íconos originales de cada tipo de dispositivo en el lienzo.

Requisitos previos
GNS3 (v2.2.x) corriendo localmente con su servidor API habilitado en el puerto 3080.

Terraform instalado.

Imágenes / Templates previamente configurados en GNS3 (MikroTik CHR y VPCS).

con los comandos 

# Inicializar proveedores y dependencias
terraform init -upgrade

# Planificar y desplegar la infraestructura
terraform apply

# Para destruir y limpiar el laboratorio
terraform destroy
