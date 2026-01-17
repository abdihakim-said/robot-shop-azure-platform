#!/bin/bash
set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║         CI/CD Setup Script                             ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI not found${NC}"
    exit 1
fi

if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}⚠️  GitHub CLI not found (optional but recommended)${NC}"
fi

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl not found${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"
echo ""

# Get Azure subscription
echo "🔍 Getting Azure subscription..."
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "Subscription ID: $SUBSCRIPTION_ID"
echo ""

# Create service principal
echo "🔐 Creating Azure Service Principal..."
echo "This will create credentials for GitHub Actions to access Azure"
echo ""

read -p "Create service principal for DEV environment? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Creating service principal..."
    
    SP_OUTPUT=$(az ad sp create-for-rbac \
        --name "github-actions-robot-shop-dev-$(date +%s)" \
        --role contributor \
        --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/robot-shop-dev-rg \
        --sdk-auth)
    
    echo ""
    echo -e "${GREEN}✅ Service Principal created${NC}"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "COPY THIS JSON - You'll need it for GitHub Secrets"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$SP_OUTPUT"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Save to file
    echo "$SP_OUTPUT" > azure-credentials-dev.json
    echo -e "${GREEN}✅ Saved to: azure-credentials-dev.json${NC}"
    echo ""
fi

# GitHub setup
echo "📦 GitHub Repository Setup"
echo ""

if command -v gh &> /dev/null; then
    read -p "Create GitHub repository? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Creating GitHub repository..."
        
        # Initialize git if needed
        if [ ! -d .git ]; then
            git init
            git add .
            git commit -m "Initial commit: Enterprise microservices platform"
        fi
        
        # Create repo
        gh repo create robot-shop-azure-platform --public --source=. --remote=origin --push || true
        
        echo -e "${GREEN}✅ Repository created${NC}"
        echo ""
    fi
    
    read -p "Add GitHub secret AZURE_CREDENTIALS? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -f azure-credentials-dev.json ]; then
            gh secret set AZURE_CREDENTIALS < azure-credentials-dev.json
            echo -e "${GREEN}✅ Secret added${NC}"
        else
            echo -e "${RED}❌ azure-credentials-dev.json not found${NC}"
        fi
        echo ""
    fi
    
    read -p "Create develop branch? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git checkout -b develop 2>/dev/null || git checkout develop
        git push -u origin develop
        echo -e "${GREEN}✅ Develop branch created${NC}"
        echo ""
    fi
else
    echo -e "${YELLOW}⚠️  GitHub CLI not installed${NC}"
    echo "Manual steps required:"
    echo "1. Create GitHub repository"
    echo "2. Add secret AZURE_CREDENTIALS with content from azure-credentials-dev.json"
    echo "3. Create develop branch"
    echo ""
fi

# Summary
echo "╔════════════════════════════════════════════════════════╗"
echo "║         Setup Summary                                  ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "✅ Service Principal created"
echo "✅ Credentials saved to azure-credentials-dev.json"
echo ""
echo "📝 Next Steps:"
echo ""
echo "1. Add GitHub Secret (if not done):"
echo "   GitHub → Settings → Secrets → New secret"
echo "   Name: AZURE_CREDENTIALS"
echo "   Value: Content of azure-credentials-dev.json"
echo ""
echo "2. Configure GitHub Environments:"
echo "   GitHub → Settings → Environments"
echo "   Create: development, staging, production"
echo "   Set production to require approval"
echo ""
echo "3. Test CI/CD:"
echo "   git checkout -b feature/test-ci"
echo "   echo '# Test' >> test.md"
echo "   git add test.md"
echo "   git commit -m 'test: CI pipeline'"
echo "   git push origin feature/test-ci"
echo "   # Create PR on GitHub"
echo ""
echo "4. Monitor workflows:"
echo "   gh run list"
echo "   gh run watch"
echo ""
echo "📚 Full guide: CICD-IMPLEMENTATION-GUIDE.md"
echo ""
echo -e "${GREEN}✅ Setup script complete!${NC}"
