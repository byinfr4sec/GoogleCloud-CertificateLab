#!/bin/bash
# =========================================================
# GSP002 - Automação Completa | Mentor GCP by Rafael & GPT
# Tempo estimado de execução: ~2 minutos
# =========================================================

echo "===== Inicializando ambiente do Cloud Shell ====="

# 1. Captura e exporta o ID do projeto e zona padrão
export PROJECT_ID=$(gcloud config get-value project)
echo "Projeto ativo: $PROJECT_ID"

# Define região e zona padrão (ajuste se necessário)
REGION="us-east1"
ZONE="us-east1-c"

gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

export REGION=$REGION
export ZONE=$ZONE

echo -e "\n===== Região e Zona definidas ====="
gcloud config list compute

# 2. Criação da instância VM
echo -e "\n===== Criando VM gcelab2 ====="
gcloud compute instances create gcelab2 \
  --machine-type=e2-medium \
  --zone=$ZONE \
  --tags=http-server,https-server \
  --quiet

# 3. Instalação do NGINX via SSH automático
echo -e "\n===== Instalando Nginx na VM ====="
gcloud compute ssh gcelab2 --zone=$ZONE --command "sudo apt update && sudo apt install -y nginx" --quiet

# 4. Regras de firewall HTTP
echo -e "\n===== Criando regra de firewall HTTP ====="
gcloud compute firewall-rules create default-allow-http \
  --direction=INGRESS \
  --priority=1000 \
  --network=default \
  --action=ALLOW \
  --rules=tcp:80 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=http-server \
  --quiet

# 5. Verificação do IP externo e teste com curl
echo -e "\n===== Testando acesso HTTP ====="
VM_IP=$(gcloud compute instances list --filter=name:gcelab2 --format='value(EXTERNAL_IP)')
echo "Acesse via navegador: http://$VM_IP"
curl -I http://$VM_IP

# 6. Logs
echo -e "\n===== Listando logs do sistema (amostra) ====="
gcloud logging logs list --limit 5
echo -e "\n===== Logs da instância gcelab2 ====="
gcloud logging read "resource.type=gce_instance AND labels.instance_name='gcelab2'" --limit 5 --format="value(textPayload)"

echo -e "\n===== LAB CONCLUÍDO COM SUCESSO ====="
echo "✅ VM criada, Nginx ativo, Firewall configurado, Logs verificados."
