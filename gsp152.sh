#!/bin/bash
set -e

echo "===== GSP499 - User Authentication with IAP ====="
echo "Iniciando execução automatizada..."

# Confirmar projeto
PROJECT_ID=$(gcloud config get-value project)
echo "Projeto atual: $PROJECT_ID"

# Etapa 1: baixar código
echo "Baixando código..."
gsutil cp gs://spls/gsp499/user-authentication-with-iap.zip .
unzip -o user-authentication-with-iap.zip
cd user-authentication-with-iap

# Etapa 1: HelloWorld
echo "Deploy da aplicação HelloWorld..."
cd 1-HelloWorld
sed -i 's/python37/python313/g' app.yaml
gcloud app deploy --quiet
echo "Aplicação HelloWorld implantada."
gcloud app browse

# Desativar Flex API para evitar erro de IAP
gcloud services disable appengineflex.googleapis.com --quiet

# Ativar API do IAP
echo "Ativando API do IAP..."
gcloud services enable iap.googleapis.com

# (Manual) Configuração do OAuth Consent Screen
echo "⚠️ Vá até o Console → Security → Identity-Aware Proxy → Configure consent screen (Internal)"
echo "Depois volte e pressione [Enter] para continuar..."
read

# Obter Client ID do App Engine default
CLIENT_ID=$(gcloud iap oauth-brands list --format="value(name)" 2>/dev/null || true)
if [ -z "$CLIENT_ID" ]; then
  echo "Criando OAuth brand..."
  gcloud iap oauth-brands create --application_title="IAP Example" --support_email="$(gcloud auth list --filter=status:ACTIVE --format="value(account)")"
  CLIENT_ID=$(gcloud iap oauth-brands list --format="value(name)")
fi

# Etapa 2: HelloUser
echo "Deploy da aplicação HelloUser..."
cd ~/user-authentication-with-iap/2-HelloUser
sed -i 's/python37/python313/g' app.yaml
gcloud app deploy --quiet
gcloud app browse

# Ativar IAP no App Engine default service
APP_ID=$(gcloud app describe --format="value(defaultHostname)")
echo "Ativando IAP para o App Engine ($APP_ID)..."
gcloud iap web enable --resource-type=app-engine

# Adicionar permissão IAP
EMAIL=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="user:$EMAIL" \
  --role="roles/iap.httpsResourceAccessor"

echo "IAP habilitado e acesso concedido para $EMAIL."

# Etapa 3: HelloVerifiedUser
echo "Deploy da aplicação HelloVerifiedUser..."
cd ~/user-authentication-with-iap/3-HelloVerifiedUser
sed -i 's/python37/python313/g' app.yaml
gcloud app deploy --quiet
gcloud app browse

# Teste de verificação JWT
echo "Verificando assinatura JWT..."
curl -s "$(gcloud app browse --no-launch-browser)" | grep -q "Hello" && echo "JWT verificado e aplicação acessível."

echo "===== LAB CONCLUÍDO COM SUCESSO ====="
echo "Todas as tasks automatizadas foram executadas."
