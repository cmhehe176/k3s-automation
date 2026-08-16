#!/bin/bash
set -euo pipefail

# ============================================
# Teardown K3s Cluster
# ============================================

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Teardown K3s cluster - remove all nodes or specific nodes.

Options:
  --all              Teardown entire cluster (all nodes)
  --node <name>      Teardown specific node only (can specify multiple)
  --control          Teardown control plane only (WARNING: destroys cluster)
  --workers          Teardown all worker nodes only
  -h, --help         Show this help message

Examples:
  # Remove entire cluster
  ./teardown.sh --all

  # Remove specific nodes
  ./teardown.sh --node node-2
  ./teardown.sh --node node-2 --node node-3

  # Remove all workers (keep control plane)
  ./teardown.sh --workers

  # Remove control plane (destroys cluster!)
  ./teardown.sh --control

EOF
    exit 1
}

# Parse arguments
TEARDOWN_ALL=false
TEARDOWN_CONTROL=false
TEARDOWN_WORKERS=false
SPECIFIC_NODES=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            TEARDOWN_ALL=true
            shift
            ;;
        --control)
            TEARDOWN_CONTROL=true
            shift
            ;;
        --workers)
            TEARDOWN_WORKERS=true
            shift
            ;;
        --node)
            if [[ -z "$2" ]]; then
                echo "❌ Error: --node requires a node name"
                exit 1
            fi
            if [[ ! "$2" =~ ^[a-zA-Z0-9._-]+$ ]]; then
                echo "❌ Error: Invalid node name '$2'. Only alphanumeric, dots, hyphens, and underscores allowed"
                exit 1
            fi
            SPECIFIC_NODES+=("$2")
            shift 2
            ;;
        -h|--help)
            show_usage
            ;;
        *)
            echo "❌ Unknown option: $1"
            show_usage
            ;;
    esac
done

# Validate arguments
if [ "$TEARDOWN_ALL" = false ] && [ "$TEARDOWN_CONTROL" = false ] && [ "$TEARDOWN_WORKERS" = false ] && [ ${#SPECIFIC_NODES[@]} -eq 0 ]; then
    echo "❌ Error: No teardown target specified"
    show_usage
fi

# Check if running from ansible directory
if [ ! -f "ansible.cfg" ]; then
    echo "❌ Error: Run this script from ansible/ directory"
    exit 1
fi

echo "============================================"
echo "K3s Cluster Teardown"
echo "============================================"
echo ""

# Determine target nodes
TARGET_LIMIT=""
if [ "$TEARDOWN_ALL" = true ]; then
    echo "⚠️  WARNING: This will teardown the ENTIRE cluster!"
    echo "All nodes (control plane + workers) will be removed."
    TARGET_LIMIT="k3s_cluster"
elif [ "$TEARDOWN_CONTROL" = true ]; then
    echo "⚠️  WARNING: This will destroy the control plane!"
    echo "The entire cluster will become non-functional."
    TARGET_LIMIT="k3s_control"
elif [ "$TEARDOWN_WORKERS" = true ]; then
    echo "Tearing down all worker nodes..."
    TARGET_LIMIT="k3s_workers"
elif [ ${#SPECIFIC_NODES[@]} -gt 0 ]; then
    echo "Tearing down specific nodes: ${SPECIFIC_NODES[*]}"
    TARGET_LIMIT=$(IFS=,; echo "${SPECIFIC_NODES[*]}")
fi

echo ""
echo "Target: $TARGET_LIMIT"
echo ""

# Confirmation
read -p "Are you sure you want to proceed? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "❌ Teardown cancelled"
    exit 0
fi

echo ""
echo "🗑️  Starting teardown..."
echo ""

# If tearing down specific workers, drain and delete them first
if [ ${#SPECIFIC_NODES[@]} -gt 0 ] || [ "$TEARDOWN_WORKERS" = true ]; then
    export KUBECONFIG=~/.kube/config-k3s

    NODES_TO_DRAIN=()
    if [ "$TEARDOWN_WORKERS" = true ]; then
        NODES_TO_DRAIN=($(ansible-inventory --list | jq -r '.k3s_workers.hosts[]' 2>/dev/null))
    else
        NODES_TO_DRAIN=("${SPECIFIC_NODES[@]}")
    fi

    for node in "${NODES_TO_DRAIN[@]}"; do
        if kubectl get node "$node" > /dev/null 2>&1; then
            echo "  → Draining $node..."
            kubectl drain "$node" --ignore-daemonsets --delete-emptydir-data --force --timeout=60s || true
            echo "  → Deleting $node from cluster..."
            kubectl delete node "$node" || true
        fi
    done
    echo ""
fi

# Run teardown playbook
echo "Running teardown playbook..."
ansible-playbook k3s/playbooks/99-teardown.yml --limit "$TARGET_LIMIT" || {
    echo "⚠️  Warning: Teardown playbook encountered errors"
}

echo ""
echo "============================================"
echo "✅ Teardown completed!"
echo "============================================"
echo ""

if [ "$TEARDOWN_ALL" = true ] || [ "$TEARDOWN_CONTROL" = true ]; then
    echo "Cluster has been destroyed."
    echo ""
    echo "To bootstrap a new cluster:"
    echo "  cd ansible/"
    echo "  ./scripts/bootstrap.sh"
else
    echo "Remaining cluster nodes:"
    export KUBECONFIG=~/.kube/config-k3s
    kubectl get nodes -o wide 2>/dev/null || echo "Cluster may be unavailable"
fi

echo ""
