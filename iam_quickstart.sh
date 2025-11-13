#!/bin/bash
echo "==============================="
echo "🧩 Cloud IAM: Qwik Start (GSP064)"
echo "Automação iniciada..."
echo "==============================="

# 1️⃣ CONFIGURAÇÕES INICIAIS
echo ""
read -p "➡️  Digite o e-mail do usuário 2 (Username 2 do painel Qwiklabs): " USER2
PROJECT_ID=$(gcloud config get-value project)
echo "📦 Projeto ativo: $PROJECT_ID"

# (opcional) definir região, caso peça:
read -p "🌎 Digite a região desejada (ex: us-central1): " REGION
REGION=${REGION:-us-central1}

echo ""
echo "⚙️ Verificando permissões atuais..."
gcloud projects get-iam-policy $PROJECT_ID --flatten="bindings[].members" --format="table(bindings.role, bindings.members)"

echo ""
echo "✅ Confirmando que você está logado como o dono (Username 1)"
gcloud auth list

echo ""
echo "==============================="
echo "TASK 2 — Criando Bucket e enviando arquivo..."
echo "==============================="

# 2️⃣ CRIAR BUCKET
BUCKET_NAME="bucket-$(date +%s)-$RANDOM"
echo "🪣 Criando bucket: $BUCKET_NAME"

gcloud storage buckets create gs://$BUCKET_NAME \
  --project=$PROJECT_ID \
  --location=$REGION \
  --uniform-bucket-level-access

# criar arquivo temporário
echo "🔧 Criando arquivo sample.txt localmente..."
echo "This is a sample file for Cloud IAM Qwiklab test." > sample.txt

# subir arquivo
echo "⬆️ Enviando arquivo sample.txt..."
gcloud storage cp sample.txt gs://$BUCKET_NAME/

echo ""
echo "📂 Verificando upload:"
gcloud storage ls gs://$BUCKET_NAME

echo ""
echo "✅ Bucket criado e arquivo enviado com sucesso!"
echo "==============================="

# 3️⃣ REMOVER ACESSO DO USUÁRIO 2 (caso já tenha)
echo "TASK 3 — Removendo acesso do usuário 2..."
gcloud projects remove-iam-policy-binding $PROJECT_ID \
  --member="user:$USER2" \
  --role="roles/viewer" \
  --quiet || echo "Nenhum binding anterior encontrado para roles/viewer."

echo "⏳ Aguardando 60 segundos para propagação..."
sleep 60

echo ""
echo "Verifique se o usuário 2 perdeu acesso no console do Qwiklabs (Cloud Storage deve mostrar erro)."
echo "==============================="

# 4️⃣ ADICIONAR ACESSO SOMENTE AO STORAGE
echo "TASK 4 — Concedendo acesso direto ao Storage..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="user:$USER2" \
  --role="roles/storage.objectViewer"

echo "✅ Permissão 'Storage Object Viewer' atribuída a $USER2"

echo ""
echo "Aguarde alguns segundos e teste o acesso via Cloud Shell do USER2:"
echo ""
echo "Comando para testar:"
echo "gsutil ls gs://$BUCKET_NAME"
echo ""
echo "Se retornar 'sample.txt', o acesso ao bucket está funcionando corretamente!"

echo ""
echo "==============================="
echo "🎉 Todas as tasks concluídas!"
echo "✅ Bucket: $BUCKET_NAME"
echo "✅ Usuário 2: $USER2"
echo "==============================="
