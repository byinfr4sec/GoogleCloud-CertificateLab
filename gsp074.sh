#!/bin/bash
# ============================================
# Google Cloud Storage: Qwik Start - CLI/SDK
# Script 100% automatizado para completar o lab
# Autor: Rafael Pereira (NuvemITech)
# ============================================

# Configurações iniciais
echo "🔧 Configurando variáveis..."
PROJECT_ID=$(gcloud config get-value project)
REGION=$(gcloud config get-value compute/region 2>/dev/null || echo "us-central1")
BUCKET="gsp074-$PROJECT_ID-$(date +%s)"
IMG="ada.jpg"
URL_IMG="https://upload.wikimedia.org/wikipedia/commons/thumb/a/a4/Ada_Lovelace_portrait.jpg/800px-Ada_Lovelace_portrait.jpg"

echo "🪣 Criando bucket: $BUCKET..."
gcloud storage buckets create gs://$BUCKET --location=$REGION

# Download do arquivo
echo "⬇️ Baixando imagem..."
curl -s $URL_IMG --output $IMG

# Upload da imagem
echo "⬆️ Enviando imagem para o bucket..."
gcloud storage cp $IMG gs://$BUCKET

# Removendo o arquivo local
rm $IMG

# Download de teste
echo "⬇️ Baixando imagem novamente para teste..."
gcloud storage cp -r gs://$BUCKET/ada.jpg .

# Criando pasta e copiando a imagem para ela
echo "📂 Criando pasta e copiando arquivo..."
gcloud storage cp gs://$BUCKET/ada.jpg gs://$BUCKET/image-folder/

# Listando conteúdo do bucket
echo "📜 Listando conteúdo do bucket..."
gcloud storage ls gs://$BUCKET

# Detalhes do objeto
echo "ℹ️ Detalhes do objeto:"
gcloud storage ls -l gs://$BUCKET/ada.jpg

# Tornando o objeto público
echo "🌍 Tornando o objeto público..."
gsutil acl ch -u AllUsers:R gs://$BUCKET/ada.jpg

PUBLIC_URL="https://storage.googleapis.com/$BUCKET/ada.jpg"
echo "✅ Objeto público disponível em:"
echo "$PUBLIC_URL"

# Removendo acesso público
echo "🔒 Removendo acesso público..."
gsutil acl ch -d AllUsers gs://$BUCKET/ada.jpg

# Deletando o arquivo principal
echo "🗑️ Excluindo objeto principal..."
gcloud storage rm gs://$BUCKET/ada.jpg

echo "✅ Script concluído com sucesso!"
echo "👉 Verifique no console do Cloud Storage seu progresso e marque as tasks como concluídas."
