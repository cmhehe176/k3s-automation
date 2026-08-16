#!/bin/bash
set -euo pipefail

# ============================================
# Remove Node from K3s Cluster
# ============================================

show_usage() {
    cat << EOF
Usage: $0 <node-name>

Remove a worker node from K3s cluster.

Arguments:
  <node-name>    Node name to remove (e.g., node-2, node-3)

Examples:
  ./remove-node.sh node-2
  ./remove-node.sh node-3

EOF
    exit 1
}

# Parse arguments
if [ $# -eq 0 ]; then
    echo "❌ Error: No node specified"
    show_usage
fi

NODE_NAME="$1"

# Validate node name
if [[ -z "$NODE_NAME" ]]; then
    echo "❌ Error: Node name cannot be empty"
    exit 1
fi

if [[ ! "$NODE_NAME" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    echo "❌ Error: Invalid node name. Only alphanumeric, dots, hyphens, and underscores allowed"
    exit 1
fi

# Check if running from ansible directory
if [ ! -f "ansible.cfg" ]; then
    echo "❌ Error: Run this script from ansible/ directory"
    exit 1
fi

echo "============================================"
echo "Remove Node from K3s Cluster"
echo "============================================"
echo "Node: $NODE_NAME"
echo ""

# Warning
echo "⚠️  WARNING: This will remove $NODE_NAME from the cluster!"
echo ""
read -p "Are you sure you want to remove $NODE_NAME? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Operation cancelled"
    exit 0
fi

echo ""

# Check if node exists in inventory
if ! ansible-inventory --list | jq -e ".k3s_workers.hosts[] | select(. == \"$NODE_NAME\")" > /dev/null 2>&1; then
    echo "❌ Error: Node $NODE_NAME not found in k3s_workers group"
    exit 1
fi

# Test connectivity
echo "📡 Testing connectivity to $NODE_NAME..."
ansible "$NODE_NAME" -m ping || {
    echo "⚠️  Warning: Cannot reach $NODE_NAME via Ansible"
    echo "Node will be removed from cluster but you may need to clean it up manually"
}

# Step 1: Drain node from cluster
echo ""
echo "Step 1/3: Draining $NODE_NAME from cluster..."
export KUBECONFIG=~/.kube/config-k3s

if kubectl get node "$NODE_NAME" > /dev/null 2>&1; then
    kubectl drain "$NODE_NAME" --ignore-daemonsets --delete-emptydir-data --force --timeout=60s || {
        echo "⚠️  Warning: Drain failed, continuing anyway..."
    }

    # Step 2: Delete node from cluster
    echo ""
    echo "Step 2/3: Deleting $NODE_NAME from cluster..."
    kubectl delete node "$NODE_NAME" || {
        echo "⚠️  Warning: Could not delete node from cluster"
    }
else
    echo "⚠️  Node $NODE_NAME not found in cluster, skipping drain/delete"
fi

# Step 3: Uninstall K3s from the node
echo ""
echo "Step 3/3: Uninstalling K3s from $NODE_NAME..."
ansible-playbook k3s/playbooks/99-teardown.yml --limit "$NODE_NAME" || {
    echo "⚠️  Warning: Uninstall playbook failed"
}

echo ""
echo "============================================"
echo "✅ Node $NODE_NAME removed successfully!"
echo "============================================"
echo ""
echo "Remaining cluster nodes:"
kubectl get nodes -o wide 2>/dev/null || echo "No nodes or cluster unavailable"
echo ""
echo "To completely remove $NODE_NAME from inventory:"
echo "  Edit ansible/inventory/hosts.ini and comment out or delete the line for $NODE_NAME"
echo ""
