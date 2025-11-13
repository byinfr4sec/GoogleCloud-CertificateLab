#!/bin/bash

# =========================================================
# Google Cloud Run Functions - Qwiklab Automation Script
# Author: Rafael "Infr4SeC" Pereira
# =========================================================

# Abort on error
set -e

# Define variables (you can override via env vars)
PROJECT_ID=$(gcloud config get-value project)
REGION=${REGION:-us-central1}
BUCKET_NAME="${PROJECT_ID}-bucket"
SERVICE_ACCOUNT="cloudfunctionsa@${PROJECT_ID}.iam.gserviceaccount.com"
TOPIC_NAME="cf-demo"
FUNCTION_NAME="nodejs-pubsub-function"

echo "🚀 Starting automation for project: $PROJECT_ID in region: $REGION"

# ---------------------------------------------------------
# Step 1. Enable APIs
# ---------------------------------------------------------
echo "🔧 Enabling required APIs..."
gcloud services enable \
  cloudfunctions.googleapis.com \
  pubsub.googleapis.com \
  artifactregistry.googleapis.com \
  run.googleapis.com \
  logging.googleapis.com

# ---------------------------------------------------------
# Step 2. Set region
# ---------------------------------------------------------
echo "🌎 Setting default region..."
gcloud config set run/region $REGION

# ---------------------------------------------------------
# Step 3. Create bucket (if not exists)
# ---------------------------------------------------------
if ! gsutil ls -b gs://$BUCKET_NAME >/dev/null 2>&1; then
  echo "🪣 Creating bucket $BUCKET_NAME..."
  gsutil mb -l $REGION gs://$BUCKET_NAME
else
  echo "✅ Bucket already exists: $BUCKET_NAME"
fi

# ---------------------------------------------------------
# Step 4. Create Pub/Sub topic
# ---------------------------------------------------------
if ! gcloud pubsub topics describe $TOPIC_NAME >/dev/null 2>&1; then
  echo "📬 Creating Pub/Sub topic $TOPIC_NAME..."
  gcloud pubsub topics create $TOPIC_NAME
else
  echo "✅ Topic already exists: $TOPIC_NAME"
fi

# ---------------------------------------------------------
# Step 5. Create Function source files
# ---------------------------------------------------------
echo "📁 Setting up source code directory..."
mkdir -p gcf_hello_world && cd gcf_hello_world

cat > index.js <<'EOF'
const functions = require('@google-cloud/functions-framework');

// Register a CloudEvent callback
functions.cloudEvent('helloPubSub', cloudEvent => {
  const base64name = cloudEvent.data.message.data;
  const name = base64name ? Buffer.from(base64name, 'base64').toString() : 'World';
  console.log(`Hello, ${name}!`);
});
EOF

cat > package.json <<'EOF'
{
  "name": "gcf_hello_world",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "@google-cloud/functions-framework": "^3.0.0"
  }
}
EOF

echo "📦 Installing dependencies..."
npm install --silent

# ---------------------------------------------------------
# Step 6. Deploy Function
# ---------------------------------------------------------
echo "🚢 Deploying Cloud Run function..."
gcloud functions deploy $FUNCTION_NAME \
  --gen2 \
  --runtime=nodejs20 \
  --region=$REGION \
  --source=. \
  --entry-point=helloPubSub \
  --trigger-topic=$TOPIC_NAME \
  --stage-bucket=$BUCKET_NAME \
  --service-account=$SERVICE_ACCOUNT \
  --allow-unauthenticated --quiet

# ---------------------------------------------------------
# Step 7. Verify deployment
# ---------------------------------------------------------
echo "🔍 Verifying function deployment..."
gcloud functions describe $FUNCTION_NAME --region=$REGION | grep "state"

# ---------------------------------------------------------
# Step 8. Publish test message
# ---------------------------------------------------------
echo "💬 Publishing test message..."
gcloud pubsub topics publish $TOPIC_NAME --message="Cloud Function Gen2"

# ---------------------------------------------------------
# Step 9. View logs (latest 10)
# ---------------------------------------------------------
echo "🧾 Fetching recent logs..."
sleep 15  # Wait a bit for logs to propagate
gcloud functions logs read $FUNCTION_NAME --region=$REGION --limit=10

echo "🎯 Done! Function deployed, tested, and verified."
