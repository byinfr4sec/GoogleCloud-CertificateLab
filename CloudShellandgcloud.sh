#!/bin/bash

echo "===== Inicializando ambiente do Cloud Shell ====="

# Solicita os dados do ambiente manualmente (pois Qwiklabs gera novos a cada execução)
read -p "Digite o PROJECT ID fornecido pelo lab (ex: qwiklabs-gcp-02-xxxx): " PROJECT_ID
read -p "Digite a REGION (ex: us-west1): " REGION
read -p "Digite a ZONE (ex: us-west1-c): " ZONE

echo ""
echo "===== Configurando projeto, região e zona ====="
gcloud config set project $PROJECT_ID
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

echo ""
echo "Projeto ativo: $(gcloud config get-value project)"
echo "Região: $(gcloud config get-value compute/region)"
echo "Zona: $(gcloud config get-value compute/zone)"
echo ""

# Define variáveis de ambiente
export PROJECT_ID=$(gcloud config get-value project)
export ZONE=$(gcloud config get-value compute/zone)
echo "Variáveis definidas:"
echo "PROJECT_ID=$PROJECT_ID"
echo "ZONE=$ZONE"

echo ""
echo "===== Criando VM gcelab2 ====="
gcloud compute instances create gcelab2 \
  --machine-type=e2-medium \
  --zone=$ZONE

echo ""
echo "===== Listando instâncias ====="
gcloud compute instances list --filter="name=('gcelab2')"

echo ""
echo "===== Conectando via SSH na VM ====="
echo "Aceite a criação da chave SSH e pressione ENTER quando solicitado..."
gcloud compute ssh gcelab2 --zone=$ZONE --command="sudo apt update && sudo apt install -y nginx"

echo ""
echo "===== Saindo da VM ====="
# o comando acima já roda e sai automaticamente após instalar o nginx

echo ""
echo "===== Adicionando tags de firewall ====="
gcloud compute instances add-tags gcelab2 --tags=http-server,https-server

echo ""
echo "===== Criando regra de firewall HTTP ====="
gcloud compute firewall-rules create default-allow-http \
  --direction=INGRESS \
  --priority=1000 \
  --network=default \
  --action=ALLOW \
  --rules=tcp:80 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=http-server

echo ""
echo "===== Verificando firewall ====="
gcloud compute firewall-rules list --filter="ALLOW:'80'"

echo ""
echo "===== Testando acesso HTTP ao Nginx ====="
EXTERNAL_IP=$(gcloud compute instances list --filter="name=('gcelab2')" --format="value(EXTERNAL_IP)")
echo "Acesse o Nginx via navegador: http://$EXTERNAL_IP"
echo "Verificando com curl:"
curl http://$EXTERNAL_IP

echo ""
echo "===== Listando logs disponíveis ====="
gcloud logging logs list --limit=5

echo ""
echo "===== Logs relacionados ao Compute Engine ====="
gcloud logging logs list --filter="compute" --limit=5

echo ""
echo "===== Logs da instância gcelab2 ====="
gcloud logging read "resource.type=gce_instance AND labels.instance_name='gcelab2'" --limit=5

echo ""
echo "===== LAB CONCLUÍDO ====="
echo "✅ VM criada, Nginx instalado, Firewall HTTP configurado, Logs verificados."
