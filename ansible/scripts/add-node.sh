#!/bin/bash
set -e

# ============================================
# Add Node to K3s Cluster
# Supports: Standard (full resources) or Flexible (custom resources)
# ============================================

# Show usage
show_usage() {
    cat << EOF
Usage: $0 <node-name> [node2] [node3] ... [OPTIONS]

Add worker node(s) to K3s cluster.

Arguments:
  <node-name>           Node name(s) to add (e.g., node-2, node-3)

Options (Flexible Configuration):
  --memory <size>       Memory limit for K3s (e.g., 16G, 8G)
                        Default: unlimited (use all RAM)
  --cpu-quota <pct>     CPU quota percentage (e.g., 50 = 50%)
                        Default: 100 (use all CPUs)
  --role <type>         Node role: worker, middleware, dual, database
                        Default: worker
  --taint <taint>       Add taint to control scheduling
                        Format: key=value:Effect (e.g., middleware=true:NoSchedule)
  --label <label>       Add custom label
                        Format: key=value (e.g., node-type=database)
  -h, --help            Show this help message

Examples:
  # Standard worker (full 32GB RAM, all CPUs)
  $0 node-2

  # Add multiple standard workers
  $0 node-2 node-3 node-4

  # Flexible: 16GB for K3s, 16GB for other services
  $0 node-3 --memory 16G --cpu-quota 50 --role dual

  # Database-dedicated node
  $0 node-4 --role database --taint database=true:NoSchedule

  # Low-resource worker
  $0 node-5 --memory 8G --cpu-quota 25

EOF
}

# Parse arguments
NODES=()
MEMORY_LIMIT=""
CPU_QUOTA="100"
NODE_ROLE="worker"
NODE_TAINT=""
NODE_LABEL=""
FLEXIBLE_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        --memory)
            MEMORY_LIMIT="$2"
            FLEXIBLE_MODE=true
            shift 2
            ;;
        --cpu-quota)
            CPU_QUOTA="$2"
            FLEXIBLE_MODE=true
            shift 2
            ;;
        --role)
            NODE_ROLE="$2"
            shift 2
            ;;
        --taint)
            NODE_TAINT="$2"
            shift 2
            ;;
        --label)
            NODE_LABEL="$2"
            shift 2
            ;;
        -*)
            echo "❌ Unknown option: $1"
            show_usage
            exit 1
            ;;
        *)
            NODES+=("$1")
            shift
            ;;
    esac
done

# Validate
if [ ${#NODES[@]} -eq 0 ]; then
    echo "❌ Error: No nodes specified"
    show_usage
    exit 1
fi

# Display configuration
echo "============================================"
echo "Add Worker Node(s) to K3s Cluster"
echo "============================================"
echo ""
echo "Nodes: ${NODES[*]}"
if [ "$FLEXIBLE_MODE" = true ]; then
    echo "Mode: Flexible Configuration"
    echo "  Memory: ${MEMORY_LIMIT:-unlimited}"
    echo "  CPU Quota: ${CPU_QUOTA}%"
    echo "  Role: ${NODE_ROLE}"
    [ -n "$NODE_TAINT" ] && echo "  Taint: ${NODE_TAINT}"
    [ -n "$NODE_LABEL" ] && echo "  Label: ${NODE_LABEL}"
else
    echo "Mode: Standard (full resources)"
fi
echo ""

# Check environment
if [ ! -f "ansible.cfg" ]; then
    echo "❌ Error: Run this script from ansible/ directory"
    exit 1
fi

if [ ! -f "/tmp/k3s-node-token" ]; then
    echo "❌ Error: K3s token not found!"
    echo "   Bootstrap control plane first: ./bootstrap.sh"
    exit 1
fi

if [ ! -f ~/.kube/config-k3s ]; then
    echo "❌ Error: Kubeconfig not found!"
    echo "   Bootstrap control plane first: ./bootstrap.sh"
    exit 1
fi

export KUBECONFIG=~/.kube/config-k3s

# Test connectivity
echo "📡 Testing connectivity..."
for node in "${NODES[@]}"; do
    echo "  - $node..."
    ansible "$node" -m ping > /dev/null 2>&1 || {
        echo "    ❌ Cannot reach $node"
        exit 1
    }
    echo "    ✅ Reachable"
done
echo ""

# Check cluster health
echo "🔍 Checking cluster health..."
kubectl get nodes > /dev/null 2>&1 || {
    echo "❌ Control plane not accessible!"
    exit 1
}
echo "✅ Cluster healthy"
echo ""

# Process each node
for node in "${NODES[@]}"; do
    echo "============================================"
    echo "Processing: $node"
    echo "============================================"

    # Check if already in cluster
    if kubectl get node "$node" > /dev/null 2>&1; then
        echo "⚠️  $node already in cluster, skipping..."
        echo ""
        continue
    fi

    echo ""
    echo "Step 1/3: Preparing $node..."
    ansible-playbook playbooks/00-prerequisites.yml --limit "$node" || {
        echo "❌ Failed to prepare $node"
        exit 1
    }

    echo ""
    echo "Step 2/3: Joining $node to cluster..."

    # Use main inventory with --limit to target specific node
    ansible-playbook playbooks/02-k3s-workers.yml --limit "$node" || {
        echo "❌ Failed to join $node"
        exit 1
    }

    echo ""
    echo "✅ $node joined!"

    # Wait for Ready
    echo "⏳ Waiting for $node Ready..."
    for i in {1..30}; do
        if kubectl get node "$node" 2>/dev/null | grep -q "Ready"; then
            echo "✅ $node Ready"
            break
        fi
        sleep 2
    done
    echo ""

    # Apply flexible config if specified
    if [ "$FLEXIBLE_MODE" = true ]; then
        echo "Step 3/3: Applying flexible configuration..."

        # Get node IP
        NODE_IP=$(ansible $node -m debug -a "var=ansible_host" | grep ansible_host | awk '{print $2}' | tr -d '"')

        # Apply resource limits
        if [ -n "$MEMORY_LIMIT" ] || [ "$CPU_QUOTA" != "100" ]; then
            echo "  → Setting resource limits..."

            ssh admin@$NODE_IP "sudo mkdir -p /etc/systemd/system/k3s-agent.service.d/"

            override_content="[Service]"
            [ -n "$MEMORY_LIMIT" ] && override_content="${override_content}\nMemoryLimit=${MEMORY_LIMIT}"
            [ "$CPU_QUOTA" != "100" ] && override_content="${override_content}\nCPUQuota=${CPU_QUOTA}%"

            echo -e "$override_content" | ssh admin@$NODE_IP "sudo tee /etc/systemd/system/k3s-agent.service.d/override.conf > /dev/null"
            ssh admin@$NODE_IP "sudo systemctl daemon-reload && sudo systemctl restart k3s-agent"

            echo "  ✅ Resource limits applied"
        fi

        # Apply labels
        if [ -n "$NODE_LABEL" ]; then
            echo "  → Adding label: $NODE_LABEL"
            kubectl label node "$node" "$NODE_LABEL" --overwrite
            echo "  ✅ Label applied"
        fi

        # Apply role label
        if [ "$NODE_ROLE" != "worker" ]; then
            echo "  → Setting role: $NODE_ROLE"
            kubectl label node "$node" "node-role.kubernetes.io/${NODE_ROLE}=true" --overwrite
            echo "  ✅ Role label applied"
        fi

        # Note: Taints are NOT applied by default to allow automatic pod load balancing
        # Kubernetes scheduler will distribute pods evenly across all nodes
        # To manually add a taint: kubectl taint node <node-name> <key>=<value>:<effect>
    else
        echo "Step 3/3: Standard configuration (no limits, no taints)"
        echo "  → Pods will be automatically distributed across all nodes"
    fi

    echo ""
done

echo "============================================"
echo "✅ All nodes added successfully!"
echo "============================================"
echo ""

# Show cluster status
echo "Cluster nodes:"
kubectl get nodes -o wide

if [ "$FLEXIBLE_MODE" = true ]; then
    echo ""
    echo "Flexible node details:"
    for node in "${NODES[@]}"; do
        if kubectl get node "$node" > /dev/null 2>&1; then
            echo ""
            echo "=== $node ==="
            kubectl describe node "$node" | grep -A 3 "Allocatable:"
            kubectl describe node "$node" | grep "Taints:"
        fi
    done
fi

echo ""
echo "✅ Ready! Pods will schedule according to node configurations."
