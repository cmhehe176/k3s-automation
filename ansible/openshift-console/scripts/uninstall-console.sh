#!/bin/bash
set -e

echo "============================================"
echo "OpenShift Console Standalone Uninstallation"
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

# Uninstall OpenShift Console
echo "🗑️  Removing OpenShift Console Standalone from K3s..."
echo ""
ansible-playbook -i inventory/hosts.ini openshift-console/playbooks/uninstall.yml "$@" || exit 1

echo ""
echo "============================================"
echo "✅ OpenShift Console uninstalled!"
echo "============================================"
echo ""
