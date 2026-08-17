#!/bin/bash
set -e

echo "============================================"
echo "KubeSphere Uninstallation"
echo "============================================"
echo ""

CONTROL_NODE="${1:-node-1}"

# Check if running from ansible directory
if [ ! -f "ansible.cfg" ]; then
    echo "❌ Error: Run this script from ansible/ directory"
    exit 1
fi

# Warning
echo "⚠️  WARNING: This will remove KubeSphere and all its components!"
echo ""
read -p "Are you sure you want to uninstall KubeSphere? (yes/no): " confirm

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

# Uninstall KubeSphere
echo "🗑️  Uninstalling KubeSphere..."
echo ""
ansible-playbook kubesphere/playbooks/uninstall.yml --ask-become-pass "$@" || exit 1

echo ""
echo "============================================"
echo "✅ KubeSphere uninstallation completed!"
echo "============================================"
echo ""
