#!/bin/bash
set -e

ENVIRONMENT=${1:-staging}
DURATION=${2:-10}

echo "🚀 Testing $ENVIRONMENT environment for $DURATION minutes"
echo "================================================"

cd terraform/environments/$ENVIRONMENT

# Deploy
echo "📦 Deploying infrastructure..."
terraform init -upgrade
terraform apply -auto-approve

# Get outputs
echo ""
echo "✅ Environment deployed!"
echo "================================================"
terraform output

# Wait
echo ""
echo "⏳ Waiting $DURATION minutes before cleanup..."
echo "   Press Ctrl+C to cancel auto-destroy"
sleep $(($DURATION * 60))

# Destroy
echo ""
echo "🗑️ Destroying infrastructure..."
terraform destroy -auto-approve

# Calculate cost
HOURLY_COST=$([ "$ENVIRONMENT" = "production" ] && echo "140" || echo "60")
COST=$(echo "scale=2; $HOURLY_COST * $DURATION / 60" | bc)

echo ""
echo "================================================"
echo "✅ Test complete!"
echo "   Duration: $DURATION minutes"
echo "   Estimated cost: \$$COST"
echo "================================================"
