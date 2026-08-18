#!/bin/bash
set -e

echo "============================================"
echo "K3s Cluster Bootstrap (First Node)"
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

# Deploy
echo "🚀 Bootstrapping K3s cluster on $CONTROL_NODE..."
echo ""

echo "Step 1/4: Preparing node..."
ansible-playbook k3s/playbooks/00-prerequisites.yml --limit "$CONTROL_NODE" || exit 1

echo ""
echo "Step 2/4: Installing K3s server..."
ansible-playbook k3s/playbooks/01-k3s-control.yml || exit 1

echo ""
echo "Step 3/4: Deploying Longhorn storage..."
ansible-playbook k3s/playbooks/04-longhorn.yml || exit 1

echo ""
echo "Step 4/5: Deploying MetalLB LoadBalancer..."
ansible-playbook k3s/playbooks/03-metallb.yml || exit 1

echo ""
echo "Step 5/5: Configuring control node as dual-purpose (control+worker)..."
export KUBECONFIG=~/.kube/config-k3s
kubectl label node "$CONTROL_NODE" node-role.kubernetes.io/worker=worker --overwrite || {
    echo "⚠️  Warning: Could not label node as worker (may need manual fix)"
}

echo ""
echo "============================================"
echo "✅ K3s cluster bootstrapped successfully!"
echo "============================================"
echo ""
echo "Control node: $CONTROL_NODE (dual-purpose: control-plane + worker)"
echo ""
echo "Cluster nodes:"
kubectl get nodes -o wide 2>/dev/null || echo "Run: export KUBECONFIG=~/.kube/config-k3s"
echo ""
echo "Next steps:"
echo "  1. Export kubeconfig:"
echo "     export KUBECONFIG=~/.kube/config-k3s"
echo ""
echo "  2. Verify cluster:"
echo "     kubectl get nodes"
echo "     kubectl get pods -A"
echo ""
echo "  3. Add worker nodes:"
echo "     ./add-node.sh node-2"
echo "     ./add-node.sh node-3"
echo "     ./add-node.sh node-4"
echo ""
echo "  4. Or add multiple workers at once:"
echo "     ./add-node.sh node-2 node-3 node-4"
