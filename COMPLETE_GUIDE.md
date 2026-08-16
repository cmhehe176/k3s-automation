# 🚀 K3s Cluster Automation - Complete Documentation

**Version**: 2.0  
**Last Updated**: 2026-08-17  
**Status**: ✅ Production Ready

---

## 📖 Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Quick Start](#quick-start)
4. [Scripts Reference](#scripts-reference)
5. [Cluster Management](#cluster-management)
6. [Pod Scheduling & Load Balancing](#pod-scheduling--load-balancing)
7. [Troubleshooting](#troubleshooting)
8. [Repository Structure](#repository-structure)

---

## Overview

Automated K3s cluster deployment on bare-metal servers using Ansible. Supports:

- **Dual-purpose control plane** (control + worker)
- **Automatic pod load balancing** (no taints by default)
- **Longhorn distributed storage** (DaemonSet-based)
- **MetalLB LoadBalancer** (L2 mode)
- **ArgoCD GitOps** (optional)
- **Flexible node management** (add/remove/teardown)

### Key Features

✅ **No Taints by Default** - All nodes accept pods, automatic load balancing  
✅ **Control Plane as Worker** - Node-1 runs both control plane and workloads  
✅ **Easy Node Management** - Add/remove nodes with single commands  
✅ **Multiple Teardown Options** - Remove specific nodes, workers only, or entire cluster  
✅ **Production Ready** - Tested on Fedora 43 and Ubuntu 24.04

---

## Architecture

```
┌─────────────────────────────────────────────────┐
│            K3s Cluster (Multi-Node)             │
├─────────────────────────────────────────────────┤
│                                                  │
│  ┌──────────────────────────────────────────┐  │
│  │  Node-1 (Control Plane + Worker)        │  │
│  │  • K3s Server (API, Scheduler, etc.)    │  │
│  │  • Runs workload pods (no taint)        │  │
│  │  • Longhorn, MetalLB, ArgoCD            │  │
│  └──────────────────────────────────────────┘  │
│                                                  │
│  ┌──────────────────────────────────────────┐  │
│  │  Node-2, Node-3... (Workers)            │  │
│  │  • K3s Agent                             │  │
│  │  • Runs workload pods                    │  │
│  │  • Longhorn storage                      │  │
│  └──────────────────────────────────────────┘  │
│                                                  │
│  Storage: Longhorn (distributed block)          │
│  LoadBalancer: MetalLB (L2 mode)                │
│  GitOps: ArgoCD (optional)                      │
└─────────────────────────────────────────────────┘
```

### Pod Scheduling Behavior

- **No taints applied** - Kubernetes scheduler distributes pods evenly across ALL nodes
- **Control plane participates** - Node-1 runs both system pods and application workloads
- **Automatic load balancing** - Based on available CPU/Memory resources
- **No tolerations needed** - Pods deploy without special configuration

---

## Quick Start

### Prerequisites

**Control Machine** (where you run Ansible):
```bash
# Fedora
sudo dnf install -y ansible kubectl jq

# Ubuntu
sudo apt install -y ansible kubectl jq

# Ansible collections
ansible-galaxy collection install kubernetes.core
```

**Target Nodes**:
- SSH access with sudo privileges
- Static IP addresses
- Fedora 43 or Ubuntu 24.04 LTS (tested)

### 1. Configure Inventory

```bash
cd k3s-automation/ansible
nano inventory/hosts.ini
```

```ini
[k3s_control]
node-1 ansible_host=192.168.1.181 ansible_user=ndmc

[k3s_workers]
node-2 ansible_host=192.168.1.143 ansible_user=laptop
# node-3 ansible_host=192.168.1.X ansible_user=username
```

### 2. Configure Variables

```bash
nano inventory/group_vars/all.yml
```

```yaml
k3s_version: v1.30.3+k3s1
metallb_ip_range: 192.168.1.100-192.168.1.150
```

### 3. Setup SSH Keys

```bash
ssh-copy-id ndmc@192.168.1.181
ssh-copy-id laptop@192.168.1.143
```

### 4. Bootstrap Cluster

```bash
./scripts/bootstrap.sh
```

**What it does:**
1. Install prerequisites (Python kubernetes library)
2. Deploy K3s control plane on node-1
3. Deploy Longhorn storage (DaemonSet)
4. Deploy MetalLB LoadBalancer
5. Label node-1 as worker (dual-purpose)

### 5. Add Worker Nodes

```bash
# Add single node
./scripts/add-node.sh node-2

# Add multiple nodes
./scripts/add-node.sh node-2 node-3
```

### 6. Verify

```bash
export KUBECONFIG=~/.kube/config-k3s
kubectl get nodes -o wide
kubectl get pods -A
```

---

## Scripts Reference

All scripts located in `ansible/scripts/`. See [Scripts README](ansible/scripts/README.md) for full documentation.

### Core Operations

| Script | Purpose | Example |
|--------|---------|---------|
| `bootstrap.sh` | Initialize cluster | `./scripts/bootstrap.sh` |
| `add-node.sh` | Add worker nodes | `./scripts/add-node.sh node-2 node-3` |
| `remove-node.sh` | Remove specific node | `./scripts/remove-node.sh node-2` |
| `teardown.sh` | Flexible cluster teardown | `./scripts/teardown.sh --all` |

### ArgoCD Operations

| Script | Purpose | Example |
|--------|---------|---------|
| `deploy-argocd.sh` | Deploy ArgoCD | `./scripts/deploy-argocd.sh` |
| `uninstall-argocd.sh` | Remove ArgoCD | `./scripts/uninstall-argocd.sh` |

### Teardown Options

```bash
# Remove entire cluster
./scripts/teardown.sh --all

# Remove specific nodes only
./scripts/teardown.sh --node node-2 --node node-3

# Remove all workers (keep control plane)
./scripts/teardown.sh --workers

# Remove control plane (destroys cluster)
./scripts/teardown.sh --control
```

---

## Cluster Management

### Adding Nodes

**Standard node** (full resources):
```bash
./scripts/add-node.sh node-2
```

**Resource-limited node**:
```bash
./scripts/add-node.sh node-2 --memory 16G --cpu-quota 50
kubectl label node node-2 memory=low
```

### Removing Nodes

```bash
# Remove specific worker
./scripts/remove-node.sh node-2
```

**What happens:**
1. Pods are drained from the node
2. Node is deleted from cluster
3. K3s is uninstalled from the node

### Checking Node Status

```bash
# List all nodes
kubectl get nodes -o wide

# Check node details
kubectl describe node node-1

# Check resource allocation
kubectl top nodes
```

---

## Pod Scheduling & Load Balancing

### Default Behavior

**All nodes accept pods** - No taints applied by default:

```bash
# Check taints on all nodes
kubectl describe nodes | grep -A 3 Taints
# Expected: Taints: <none>
```

**Automatic distribution**:
- Kubernetes scheduler balances pods across all nodes
- Based on available CPU/Memory resources
- Control plane (node-1) also runs workload pods

### Verify Load Balancing

```bash
# Check pod distribution
kubectl get pods -A -o wide --field-selector=spec.nodeName=node-1 | wc -l
kubectl get pods -A -o wide --field-selector=spec.nodeName=node-2 | wc -l

# Expected: Pods distributed evenly
```

### Manual Pod Placement (Advanced)

**Node selector** (hard requirement):
```yaml
spec:
  nodeSelector:
    kubernetes.io/hostname: node-2
```

**Node affinity** (soft preference):
```yaml
spec:
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        preference:
          matchExpressions:
          - key: memory
            operator: NotIn
            values:
            - low
```

**Manual taint** (prevent scheduling):
```bash
# Add taint
kubectl taint node node-2 dedicated=special:NoSchedule

# Pods need toleration to schedule
tolerations:
- key: dedicated
  operator: Equal
  value: special
  effect: NoSchedule

# Remove taint
kubectl taint node node-2 dedicated=special:NoSchedule-
```

---

## Troubleshooting

### Common Issues

#### 1. Longhorn Playbook Fails

**Issue**: "Wait for Longhorn manager deployment" fails

**Root cause**: Longhorn uses DaemonSet, not Deployment

**Fix**: Already fixed in playbook `04-longhorn.yml`

```bash
# Verify Longhorn architecture
kubectl get daemonset -n longhorn-system
# Expected: longhorn-manager DaemonSet exists
```

#### 2. Python kubernetes Library Missing

**Issue**: MetalLB playbook fails "Failed to import kubernetes library"

**Fix**: Already auto-installed in `00-prerequisites.yml`

```bash
# Manual verification
python3 -c "import kubernetes; print(kubernetes.__version__)"
```

#### 3. Pods Stuck in Pending

```bash
# Describe pod to see why
kubectl describe pod <pod-name>

# Common causes:
# - Insufficient resources (check: kubectl top nodes)
# - PVC not binding (check: kubectl get pvc)
# - Node selector not matching (check pod spec)
```

#### 4. LoadBalancer IP Not Assigned

```bash
# Check MetalLB speaker logs
kubectl logs -n metallb-system -l component=speaker

# Check IP pool configuration
kubectl get ipaddresspool -n metallb-system -o yaml

# Common issues:
# - IP range conflicts with DHCP
# - MetalLB speaker pods not running
```

#### 5. Node Not Ready

```bash
# Check node status
kubectl describe node <node-name>

# Check K3s logs on the node
ssh user@node "sudo journalctl -u k3s-agent -f"

# Common causes:
# - Network connectivity issues
# - K3s service not running
# - Resource exhaustion
```

### Reset Cluster

```bash
# Complete teardown
./scripts/teardown.sh --all

# Bootstrap fresh cluster
./scripts/bootstrap.sh
```

### Get Help

```bash
# Check script usage
./scripts/<script-name>.sh --help

# View playbook tasks
ansible-playbook playbooks/<playbook>.yml --list-tasks
```

---

## Repository Structure

```
k3s-automation/
├── README.md                      # Main overview
├── COMPLETE_GUIDE.md              # This file - complete documentation
├── ansible/
│   ├── ansible.cfg                # Ansible configuration
│   ├── scripts/                   # Management scripts
│   │   ├── README.md              # Scripts documentation
│   │   ├── bootstrap.sh           # Initialize cluster
│   │   ├── add-node.sh            # Add worker nodes
│   │   ├── remove-node.sh         # Remove specific node
│   │   ├── teardown.sh            # Flexible cluster teardown
│   │   ├── deploy-argocd.sh       # Deploy ArgoCD
│   │   └── uninstall-argocd.sh    # Remove ArgoCD
│   ├── inventory/
│   │   ├── hosts.ini              # Node IPs and users
│   │   └── group_vars/
│   │       ├── all.yml            # Global variables
│   │       ├── k3s_control.yml    # Control plane vars
│   │       └── k3s_workers.yml    # Worker vars
│   ├── playbooks/                 # Ansible playbooks
│   │   ├── 00-prerequisites.yml   # Prepare nodes
│   │   ├── 01-k3s-control.yml     # K3s control plane
│   │   ├── 02-k3s-workers.yml     # K3s workers
│   │   ├── 03-metallb.yml         # MetalLB LoadBalancer
│   │   ├── 04-longhorn.yml        # Longhorn storage
│   │   ├── 05-argocd.yml          # ArgoCD deployment
│   │   ├── 05-argocd-uninstall.yml # ArgoCD removal
│   │   └── 99-teardown.yml        # Cluster teardown
│   └── roles/                     # Ansible roles
│       ├── common/                # Base OS configuration
│       ├── k3s-server/            # Control plane setup
│       └── k3s-agent/             # Worker setup
├── docs/
│   ├── README.md                  # Documentation index
│   ├── guides/
│   │   ├── deployment.md          # Deployment guide
│   │   └── add-nodes.md           # Node management
│   ├── operations/
│   │   ├── requirements.md        # System requirements
│   │   ├── security.md            # Security practices
│   │   ├── brainstorm.md          # Architecture notes
│   │   └── code-review.md         # Code review
│   └── reference/
│       ├── inventory.md           # Inventory config
│       └── fedora-notes.md        # Fedora-specific notes
└── manifests/
    └── namespaces.yaml            # Base K8s manifests
```

---

## Additional Documentation

- **[Deployment Guide](docs/guides/deployment.md)** - Detailed step-by-step deployment
- **[Add Nodes Guide](docs/guides/add-nodes.md)** - Advanced node management
- **[Scripts README](ansible/scripts/README.md)** - Complete scripts reference
- **[Requirements](docs/operations/requirements.md)** - System requirements
- **[Security](docs/operations/security.md)** - Security best practices
- **[Inventory Reference](docs/reference/inventory.md)** - Inventory configuration

---

## Summary - Key Points

### ✅ What Makes This Different

1. **No Taints** - All nodes accept pods by default, automatic load balancing
2. **Dual-Purpose Control** - Node-1 runs both control plane and workloads
3. **Flexible Teardown** - Remove specific nodes, workers only, or entire cluster
4. **Auto-Fixed Issues** - Longhorn DaemonSet, Python kubernetes lib auto-installed
5. **Scripts Organized** - All management scripts in `ansible/scripts/`

### 📌 Common Commands

```bash
# Initial setup
./scripts/bootstrap.sh

# Add workers
./scripts/add-node.sh node-2 node-3

# Deploy ArgoCD
./scripts/deploy-argocd.sh

# Remove a node
./scripts/remove-node.sh node-2

# Teardown cluster
./scripts/teardown.sh --all
```

### 🎯 Current Cluster State

After following this guide, you will have:

- **Node-1**: Control plane + worker (Fedora 43)
- **Node-2**: Worker (Ubuntu 24.04, 16GB RAM, labeled `memory=low`)
- **Longhorn**: Distributed storage across all nodes
- **MetalLB**: LoadBalancer IPs from 192.168.1.100-150
- **ArgoCD**: GitOps at https://192.168.1.100
- **Auto Load Balancing**: Pods distributed evenly across all nodes

---

**Maintainer**: Congminh  
**Version**: 2.0  
**Last Updated**: 2026-08-17  
**Status**: ✅ Production Ready
