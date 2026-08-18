#!/bin/bash
set -e

echo "============================================"
echo "KubeSphere Deployment"
echo "============================================"
echo ""

CONTROL_NODE="${1:-${DEFAULT_CONTROL_NODE:-node-1}}"

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

# Deploy KubeSphere
echo "🚀 Deploying KubeSphere Core via Helm..."
echo ""
ansible-playbook kubesphere/playbooks/deploy.yml --ask-become-pass "$@" || exit 1

echo ""
echo "============================================"
echo "✅ KubeSphere deployment finished!"
echo "============================================"
echo ""
