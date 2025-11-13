#!/bin/bash
# =========================================================
# Google Kubernetes Engine - Qwik Start (GSP100)
# Full Automation Script
# =========================================================
# Autor: Rafael / NuvemITech (assistido por GPT-5)
# =========================================================

set -e  # Abort on error

# --------------------------
# CONFIGURAÇÕES INICIAIS
# --------------------------
PROJECT_ID=$(gcloud config get-value project)
REGION=${REGION:-us-west1}
ZONE=${ZONE:-us-west1-c}
CLUSTER_NAME="lab-cluster"
DEPLOYMENT_NAME="hello-server"
IMAGE="gcr.io/google-samples/hello-app:1.0"
PORT=8080

echo "🚀 Iniciando automação do Lab GKE (Projeto: $PROJECT_ID | Região: $REGION | Zona: $ZONE)"

# --------------------------
# ETAPA 1 - DEFINIR REGIÃO E ZONA
# --------------------------
echo "🌎 Definindo região e zona padrão..."
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

# --------------------------
# ETAPA 2 - CRIAR CLUSTER GKE
# --------------------------
echo "🔧 Criando cluster Kubernetes ($CLUSTER_NAME)..."
gcloud container clusters create $CLUSTER_NAME \
  --machine-type=e2-medium \
  --num-nodes=3 \
  --zone=$ZONE \
  --quiet

echo "✅ Cluster criado com sucesso."

# --------------------------
# ETAPA 3 - AUTENTICAR NO CLUSTER
# --------------------------
echo "🔑 Obtendo credenciais do cluster..."
gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE
echo "✅ Conectado ao cluster $CLUSTER_NAME."

# --------------------------
# ETAPA 4 - DEPLOY DA APLICAÇÃO
# --------------------------
echo "📦 Criando deployment $DEPLOYMENT_NAME..."
kubectl create deployment $DEPLOYMENT_NAME --image=$IMAGE
sleep 5

echo "🌐 Expondo o deployment com LoadBalancer..."
kubectl expose deployment $DEPLOYMENT_NAME --type=LoadBalancer --port=$PORT

echo "⏳ Aguardando IP externo..."
for i in {1..15}; do
  EXTERNAL_IP=$(kubectl get svc $DEPLOYMENT_NAME --output=jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
  if [[ -n "$EXTERNAL_IP" ]]; then
    echo "✅ IP externo obtido: $EXTERNAL_IP"
    break
  else
    echo "Aguardando geração do IP ($i/15)..."
    sleep 10
  fi
done

if [[ -z "$EXTERNAL_IP" ]]; then
  echo "⚠️ IP externo ainda pendente. Tente novamente manualmente com: kubectl get svc"
else
  echo "🌍 Teste a aplicação em: http://$EXTERNAL_IP:$PORT"
fi

# --------------------------
# ETAPA 5 - MOSTRAR STATUS
# --------------------------
echo "📊 Resumo dos recursos:"
kubectl get all

# --------------------------
# ETAPA 6 - TESTE DE CONEXÃO (opcional)
# --------------------------
echo "🔍 Testando resposta HTTP (curl)..."
if [[ -n "$EXTERNAL_IP" ]]; then
  sleep 5
  curl -s "http://$EXTERNAL_IP:$PORT" || echo "⚠️ Falha ao acessar aplicação."
else
  echo "❌ IP externo não disponível para teste automático."
fi

# --------------------------
# ETAPA 7 - LIMPAR RECURSOS
# --------------------------
echo "🧹 Limpando recursos (excluindo cluster)..."
yes | gcloud container clusters delete $CLUSTER_NAME --zone=$ZONE --quiet

echo "✅ Cluster removido. Lab concluído com sucesso!"
echo "🎯 Fim da automação - GKE Qwik Start (GSP100)"
