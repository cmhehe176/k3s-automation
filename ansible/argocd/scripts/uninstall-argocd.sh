#!/bin/bash
set -e

echo "============================================"
echo "ArgoCD Uninstallation"
echo "============================================"
echo ""

CONTROL_NODE="${1:-${DEFAULT_CONTROL_NODE:-node-1}}"

# Check if running from ansible directory
if [ ! -f "ansible.cfg" ]; then
    echo "❌ Error: Run this script from ansible/ directory"
    exit 1
fi

# Warning
echo "⚠️  WARNING: This will remove ArgoCD and all its applications!"
echo ""
read -p "Are you sure you want to uninstall ArgoCD? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Uninstallation cancelled"
    exit 0
fi

echo ""

# Test connectivity
echo "📡 Testing connectivity to $CONTROL_NODE..."
ansible "$CONTROL_NODE" -m ping || {
    echo "❌ Cannot reach $CONTROL_NODE. Check inventory and SSH access."
    exit 1
}

echo "✅ $CONTROL_NODE reachable"
echo ""

# Uninstall ArgoCD
echo "🗑️  Uninstalling ArgoCD..."
echo ""
ansible-playbook argocd/playbooks/uninstall.yml || exit 1

echo ""
echo "============================================"
echo "✅ ArgoCD uninstallation completed!"
echo "============================================"
echo ""
