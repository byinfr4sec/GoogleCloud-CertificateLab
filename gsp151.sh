#!/bin/bash
# =====================================================
# Google Cloud SQL for MySQL: Qwik Start (GSP151)
# Script 100% automatizado (Cloud Shell)
# =====================================================

set -e

echo "🚀 Iniciando lab Cloud SQL for MySQL (GSP151)..."
PROJECT_ID=$(gcloud config get-value project)
REGION="us-central1"
INSTANCE="myinstance"
PASSWORD="LabPass123!"

echo "🔧 Criando instância Cloud SQL..."
gcloud sql instances create $INSTANCE \
  --database-version=MYSQL_8_0 \
  --tier=db-custom-4-16384 \
  --region=$REGION \
  --root-password=$PASSWORD \
  --assign-ip   # <- habilita IP público para conexão via Cloud Shell

echo "⏳ Aguardando instância inicializar..."
until [[ $(gcloud sql instances describe $INSTANCE --format='value(state)') == "RUNNABLE" ]]; do
  echo "   -> Instância ainda não pronta, aguardando 10s..."
  sleep 10
done

echo "✅ Instância pronta!"

echo "🧠 Criando banco de dados guestbook..."
gcloud sql databases create guestbook --instance=$INSTANCE

echo "📦 Criando tabela e inserindo dados..."
gcloud sql connect $INSTANCE --user=root --quiet --command="
CREATE DATABASE IF NOT EXISTS guestbook;
USE guestbook;
CREATE TABLE IF NOT EXISTS entries (
  guestName VARCHAR(255),
  content VARCHAR(255),
  entryID INT NOT NULL AUTO_INCREMENT,
  PRIMARY KEY(entryID)
);
INSERT INTO entries (guestName, content) VALUES ('first guest', 'I got here!');
INSERT INTO entries (guestName, content) VALUES ('second guest', 'Me too!');
SELECT * FROM entries;
" --password=$PASSWORD

echo "📋 Verificando dados inseridos..."
gcloud sql connect $INSTANCE --user=root --quiet --command="USE guestbook; SELECT * FROM entries;" --password=$PASSWORD

echo "✅ Tudo pronto! Instância criada, banco populado e dados listados com sucesso."
echo "💡 Agora clique em 'Check my progress' nas etapas do Qwiklabs."
