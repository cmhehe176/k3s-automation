#!/bin/bash
set -e

echo "============================================"
echo "Uninstall Logging Stack (ECK / ELK / Vector)"
echo "============================================"
echo ""

CONTROL_NODE="${1:-${DEFAULT_CONTROL_NODE:-node-1}}"

if [ ! -f "ansible.cfg" ]; then
    echo "❌ Error: Run this script from ansible/ directory"
    exit 1
fi

echo "⚠️  Uninstalling Logging Stack from K3s..."
echo ""
ansible-playbook -i inventory/hosts.ini logging/playbooks/uninstall.yml "$@" || exit 1

echo ""
echo "============================================"
echo "✅ Logging stack uninstalled successfully!"
echo "============================================"
echo ""
