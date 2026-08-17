# 🔧 K3s Cluster Management Scripts

Scripts for K3s cluster lifecycle management.

---

## 📋 Available Scripts

### `bootstrap.sh`
Bootstrap a new K3s cluster from scratch.

```bash
./k3s/scripts/bootstrap.sh [control-node-name]

# Default uses node-1
./k3s/scripts/bootstrap.sh

# Specify custom control node
./k3s/scripts/bootstrap.sh node-1
```

**What it does:**
1. Install prerequisites (Python kubernetes library)
2. Deploy K3s control plane
3. Deploy Longhorn storage
4. Deploy MetalLB load balancer
5. Configure control node as dual-purpose (control+worker)

---

### `add-node.sh`
Add worker nodes to existing cluster.

```bash
./k3s/scripts/add-node.sh <node-name> [node2] [node3] ...

# Add single node
./k3s/scripts/add-node.sh node-2

# Add multiple nodes
./k3s/scripts/add-node.sh node-2 node-3 node-4

# With resource limits
./k3s/scripts/add-node.sh node-2 --memory 16G --cpu-quota 50
```

**Features:**
- No taints applied by default (automatic load balancing)
- Support for resource limits (memory/CPU quotas)
- Parallel node addition

---

### `remove-node.sh`
Remove a specific worker node from cluster.

```bash
./k3s/scripts/remove-node.sh <node-name>

# Example
./k3s/scripts/remove-node.sh node-2
```

**What it does:**
1. Drain pods from the node
2. Delete node from cluster
3. Uninstall K3s from the node

---

### `teardown.sh`
Teardown cluster - flexible options for different scenarios.

```bash
# Remove entire cluster
./k3s/scripts/teardown.sh --all

# Remove specific nodes
./k3s/scripts/teardown.sh --node node-2
./k3s/scripts/teardown.sh --node node-2 --node node-3

# Remove all workers (keep control plane)
./k3s/scripts/teardown.sh --workers

# Remove control plane (destroys cluster!)
./k3s/scripts/teardown.sh --control
```

**Options:**
- `--all` - Teardown entire cluster (all nodes)
- `--node <name>` - Teardown specific node(s)
- `--workers` - Remove all worker nodes only
- `--control` - Remove control plane (destroys cluster)

---

## 🚀 Common Workflows

### Initial Setup
```bash
cd ansible/

# 1. Bootstrap cluster
./k3s/scripts/bootstrap.sh

# 2. Add worker nodes
./k3s/scripts/add-node.sh node-2 node-3
```

### Add/Remove Nodes
```bash
# Add a new worker
./k3s/scripts/add-node.sh node-4

# Remove a worker
./k3s/scripts/remove-node.sh node-4
```

### Complete Teardown
```bash
# Remove everything
./k3s/scripts/teardown.sh --all
```

### Partial Teardown
```bash
# Keep control plane, remove workers
./k3s/scripts/teardown.sh --workers

# Then re-add workers
./k3s/scripts/add-node.sh node-2 node-3
```

---

## 📋 Prerequisites

All scripts must be run from the `ansible/` directory:

```bash
cd /path/to/k3s-automation/ansible
./k3s/scripts/<script-name>.sh
```

**Requirements:**
- Ansible installed
- SSH access to all target nodes
- `kubectl` installed (for teardown operations)
- Inventory file configured (`inventory/hosts.ini`)

---

**Last Updated**: 2026-08-16  
**Maintainer**: Congminh
