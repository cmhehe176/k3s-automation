# 🔧 K3s Automation Scripts

Management scripts for K3s cluster operations.

---

## 📁 Available Scripts

### Core Cluster Management

#### `bootstrap.sh`
Bootstrap a new K3s cluster from scratch.

```bash
./scripts/bootstrap.sh [control-node-name]

# Default uses node-1
./scripts/bootstrap.sh

# Specify custom control node
./scripts/bootstrap.sh node-1
```

**What it does:**
1. Install prerequisites (Python kubernetes library)
2. Deploy K3s control plane
3. Deploy Longhorn storage
4. Deploy MetalLB load balancer
5. Configure control node as dual-purpose (control+worker)

---

#### `add-node.sh`
Add worker nodes to existing cluster.

```bash
./scripts/add-node.sh <node-name> [node2] [node3] ...

# Add single node
./scripts/add-node.sh node-2

# Add multiple nodes
./scripts/add-node.sh node-2 node-3 node-4

# With resource limits
./scripts/add-node.sh node-2 --memory 16G --cpu-quota 50
```

**Features:**
- No taints applied by default (automatic load balancing)
- Support for resource limits (memory/CPU quotas)
- Parallel node addition

---

#### `remove-node.sh`
Remove a specific worker node from cluster.

```bash
./scripts/remove-node.sh <node-name>

# Example
./scripts/remove-node.sh node-2
```

**What it does:**
1. Drain pods from the node
2. Delete node from cluster
3. Uninstall K3s from the node

---

#### `teardown.sh`
Teardown cluster - flexible options for different scenarios.

```bash
# Remove entire cluster
./scripts/teardown.sh --all

# Remove specific nodes
./scripts/teardown.sh --node node-2
./scripts/teardown.sh --node node-2 --node node-3

# Remove all workers (keep control plane)
./scripts/teardown.sh --workers

# Remove control plane (destroys cluster!)
./scripts/teardown.sh --control
```

**Options:**
- `--all` - Teardown entire cluster (all nodes)
- `--node <name>` - Teardown specific node(s)
- `--workers` - Remove all worker nodes only
- `--control` - Remove control plane (destroys cluster)

---

### ArgoCD Management

#### `deploy-argocd.sh`
Deploy ArgoCD to the cluster.

```bash
./scripts/deploy-argocd.sh
```

**What it does:**
1. Create argocd namespace
2. Deploy ArgoCD v2.12.0
3. Configure LoadBalancer service
4. Display access credentials

---

#### `uninstall-argocd.sh`
Remove ArgoCD from the cluster.

```bash
./scripts/uninstall-argocd.sh
```

**What it does:**
1. Delete all ArgoCD applications
2. Remove ArgoCD namespace
3. Clean up resources

---

## 🚀 Common Workflows

### Initial Setup
```bash
cd ansible/

# 1. Bootstrap cluster
./scripts/bootstrap.sh

# 2. Add worker nodes
./scripts/add-node.sh node-2 node-3

# 3. Deploy ArgoCD (optional)
./scripts/deploy-argocd.sh
```

### Add/Remove Nodes
```bash
# Add a new worker
./scripts/add-node.sh node-4

# Remove a worker
./scripts/remove-node.sh node-4
```

### Complete Teardown
```bash
# Remove everything
./scripts/teardown.sh --all
```

### Partial Teardown
```bash
# Keep control plane, remove workers
./scripts/teardown.sh --workers

# Then re-add workers
./scripts/add-node.sh node-2 node-3
```

---

## 📋 Prerequisites

All scripts must be run from the `ansible/` directory:

```bash
cd /path/to/k3s-automation/ansible
./scripts/<script-name>.sh
```

**Requirements:**
- Ansible installed
- SSH access to all target nodes
- `kubectl` installed (for teardown operations)
- Inventory file configured (`inventory/hosts.ini`)

---

## 🔗 Related Documentation

- [Deployment Guide](../docs/guides/deployment.md) - Complete setup guide
- [Add Nodes Guide](../docs/guides/add-nodes.md) - Detailed node management
- [Inventory Configuration](../docs/reference/inventory.md) - Inventory setup

---

**Last Updated**: 2026-08-17  
**Maintainer**: Congminh
