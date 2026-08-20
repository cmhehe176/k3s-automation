#!/bin/bash
set -e

echo "============================================"
echo "Production Logging Stack (ECK / ELK / Vector)"
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

# Deploy Logging Stack
echo "🚀 Deploying Logging Stack (Elasticsearch, Kibana, APM, Vector) on K3s..."
echo ""
ansible-playbook -i inventory/hosts.ini logging/playbooks/deploy.yml "$@" || exit 1

echo ""
echo "============================================"
echo "✅ Logging stack deployment finished!"
echo "============================================"
echo ""
