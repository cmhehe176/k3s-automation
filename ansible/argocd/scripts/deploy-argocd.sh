#!/bin/bash
set -e

echo "============================================"
echo "ArgoCD Deployment"
echo "============================================"
echo ""

CONTROL_NODE="${1:-node-1}"

# Check if running from ansible directory
if [ ! -f "ansible.cfg" ]; then
    echo "❌ Error: Run this script from ansible/ directory"
    exit 1
fi

# Test connectivity
echo "📡 Testing connectivity to $CONTROL_NODE..."
ansible "$CONTROL_NODE" -m ping || {
    echo "❌ Cannot reach $CONTROL_NODE. Check inventory and SSH access."
    exit 1
}

echo "✅ $CONTROL_NODE reachable"
echo ""

# Deploy ArgoCD
echo "🚀 Deploying ArgoCD..."
echo ""
ansible-playbook argocd/playbooks/deploy.yml || exit 1

echo ""
echo "============================================"
echo "✅ ArgoCD deployed successfully!"
echo "============================================"
echo ""
echo "Next steps:"
echo "  1. Access ArgoCD UI at the LoadBalancer IP shown above"
echo "  2. Login with username 'admin' and the password displayed"
echo "  3. Change default password:"
echo "     argocd account update-password"
echo ""
echo "  4. Configure your first application:"
echo "     kubectl apply -f /path/to/application.yaml"
echo ""
