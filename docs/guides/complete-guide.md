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
│  │  • Longhorn, MetalLB, ArgoCD, KubeSphere │  │
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
│  GitOps: ArgoCD (argocd namespace)              │
│  Console: KubeSphere Core v4 (kubesphere-system)│
└─────────────────────────────────────────────────┘
```

### Namespace Architecture & Isolation

Every system component and workload is isolated into dedicated namespaces:

| Namespace | Category | Purpose | Managed By |
|---|---|---|---|
| `kube-system` | Core | CoreDNS, Flannel CNI, Metrics Server | K3s System |
| `metallb-system` | Network | MetalLB Controller & Speakers | `03-metallb.yml` |
| `longhorn-system` | Storage | Longhorn CSI, Engine & Manager | `04-longhorn.yml` |
| `openshift-console` | Management | OpenShift Console Standalone & Dex OIDC | `openshift-console/deploy.yml` |
| `oracle` | Database | Oracle Database 19c/23ai (Port 31521) | `oracle/deploy.yml` |
| `redis` | Cache/Store | Redis Cluster 16k Hash Slots (Port 31379) | `redis/deploy.yml` |
| `redpanda` | Streaming | Redpanda Kafka (Port 31092) & Console (31080) | `redpanda/deploy.yml` |
| `minio` | Storage | MinIO S3 API (Port 31900) & Console (31901) | `minio/deploy.yml` |
| `argocd` | GitOps | ArgoCD Server, Controller, Redis | `argocd/deploy.yml` |
| `kubesphere-system`| Management | KubeSphere Core v4 Console & API | `kubesphere/deploy.yml` |

### Resource Footprint & Hardware Sizing

| Component | RAM Consumption | CPU Profile | Notes |
|---|---|---|---|
| **K3s Control Plane** | ~500 MB – 1 GB | 0.2 – 0.5 Core | API Server, Kine/etcd, Flannel |
| **K3s Worker Agent** | ~150 MB – 300 MB | 0.1 – 0.2 Core | Kubelet + containerd shim |
| **MetalLB** | ~50 MB – 100 MB | < 0.1 Core | Lightweight L2 LoadBalancer |
| **Longhorn CSI** | ~800 MB – 1.5 GB | 0.3 – 0.8 Core | Replicated block storage & CSI |
| **ArgoCD** | ~300 MB – 600 MB | 0.2 – 0.5 Core | GitOps continuous delivery |
| **KubeSphere Core (v4)** | ~500 MB – 800 MB | 0.3 – 0.5 Core | Modern microkernel web console |
| **Total Baseline Idle** | **~3.5 GB – 4.5 GB** | **~1.5 – 2.5 Cores** | Complete stack running idle |

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
nano ansible/inventory/hosts.ini
```

```ini
[k3s_control]
node-1 ansible_host=192.168.1.181 ansible_user=ndmc

[k3s_workers]
# node-2 ansible_host=192.168.1.182 ansible_user=ndmc
```

### 2. Configure Vault & Secrets (Credentials Management)

All cluster tokens, database passwords, S3 keys, and OpenShift Console admin credentials are centrally managed in `inventory/group_vars/all/vault.yml`:

```bash
# Create your local vault.yml from the provided template
cp ansible/inventory/group_vars/all/vault.example.yml ansible/inventory/group_vars/all/vault.yml

# Edit passwords or customize environment variable mappings
nano ansible/inventory/group_vars/all/vault.yml
```

> [!NOTE]
> `inventory/group_vars/all/vault.yml` and `vault.yaml` are automatically **IGNORED by Git**. Your secrets remain strictly local.
> To encrypt the vault file with AES-256:
> ```bash
> ansible-vault encrypt ansible/inventory/group_vars/all/vault.yml
> ```

### 3. Deploy Everything with Master CLI

```bash
# Deploy entire cluster + all middleware in 1 step (Strict Ordering):
./cluster.sh deploy-all

# Or launch the interactive terminal UI:
./cluster.sh
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
./k3s/scripts/add-node.sh node-2

# Add multiple nodes
./k3s/scripts/add-node.sh node-2 node-3
```

### 6. Verify

```bash
export KUBECONFIG=~/.kube/config-k3s
kubectl get nodes -o wide
kubectl get pods -A
```

---

## Scripts Reference

Scripts organized by application. See [Scripts Index](ansible/scripts/README.md) for navigation.

- **K3s Scripts**: [ansible/k3s/scripts/README.md](ansible/k3s/scripts/README.md)
- **ArgoCD Scripts**: [ansible/argocd/scripts/README.md](ansible/argocd/scripts/README.md)

### Core Operations

| Script | Purpose | Example |
|--------|---------|---------|
| `bootstrap.sh` | Initialize cluster | `./k3s/scripts/bootstrap.sh` |
| `add-node.sh` | Add worker nodes | `./k3s/scripts/add-node.sh node-2 node-3` |
| `remove-node.sh` | Remove specific node | `./k3s/scripts/remove-node.sh node-2` |
| `teardown.sh` | Flexible cluster teardown | `./k3s/scripts/teardown.sh --all` |

### ArgoCD Operations

| Script | Purpose | Example |
|--------|---------|---------|
| `deploy-argocd.sh` | Deploy ArgoCD | `./argocd/scripts/deploy-argocd.sh` |
| `uninstall-argocd.sh` | Remove ArgoCD | `./argocd/scripts/uninstall-argocd.sh` |

### Teardown Options

```bash
# Remove entire cluster
./k3s/scripts/teardown.sh --all

# Remove specific nodes only
./k3s/scripts/teardown.sh --node node-2 --node node-3

# Remove all workers (keep control plane)
./k3s/scripts/teardown.sh --workers

# Remove control plane (destroys cluster)
./k3s/scripts/teardown.sh --control
```

---

## Cluster Management

### Adding Nodes

**Standard node** (full resources):
```bash
./k3s/scripts/add-node.sh node-2
```

**Resource-limited node**:
```bash
./k3s/scripts/add-node.sh node-2 --memory 16G --cpu-quota 50
kubectl label node node-2 memory=low
```

### Removing Nodes

```bash
# Remove specific worker
./k3s/scripts/remove-node.sh node-2
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

#### 6. Longhorn Volume Permission Denied (errno=13)

**Issue**: Non-root container pods (e.g. `oracle` UID 54321, `redpanda` UID 101) crash with `Permission denied (errno=13)` when writing to mounted Longhorn volumes.

**Root cause**: Newly provisioned Longhorn PVCs have root ownership (`root:root`, mode `0755`) by default.

**Fix**: Add an `initContainer` running as root (`runAsUser: 0`) to grant full access before the main container starts:
```yaml
initContainers:
- name: fix-permissions
  image: busybox:latest
  command: ["sh", "-c", "chmod -R 777 /data"]
  volumeMounts:
  - name: storage
    mountPath: /data
  securityContext:
    runAsUser: 0
```

#### 7. Invalid NodePort Range Error

**Issue**: `The Service is invalid: spec.ports[0].nodePort: Invalid value: provided port is not in the valid range.`

**Root cause**: Kubernetes enforces NodePorts strictly within the `30000-32767` range.

**Fix**: Ensure all custom services are assigned ports within `30000-32767` (e.g. Oracle: `31521`, Redis: `31379`, Redpanda: `31092`/`31080`, MinIO: `31900`/`31901`).

### Reset Cluster

```bash
# Complete teardown
./k3s/scripts/teardown.sh --all

# Bootstrap fresh cluster
./k3s/scripts/bootstrap.sh
```

### Get Help

```bash
# Check script usage
./k3s/scripts/<script-name>.sh --help

# View playbook tasks
ansible-playbook playbooks/<playbook>.yml --list-tasks
```

---

## Repository Structure

```
k3s-automation/
├── cluster.sh                 # Root CLI & TUI wrapper
├── README.md                  # Landing page
├── docs/                      # Centralized documentation
│   ├── README.md              # Documentation sitemap
│   ├── guides/                # Step-by-step guides (this guide)
│   ├── operations/            # Requirements, security, brainstorm
│   ├── reference/             # Inventory config, fedora notes
│   └── reviews/               # Code reviews and audits
└── ansible/                   # Automation codebase
    ├── cluster.sh             # Master CLI & TUI script
    ├── inventory/             # Hosts & group_vars
    ├── k3s/                   # Core K3s, MetalLB, Longhorn, Teardown
    ├── openshift-console/     # OpenShift Console & Dex OIDC
    ├── oracle/                # Oracle Database 19c/23ai
    ├── redis/                 # Redis Cluster
    ├── redpanda/              # Redpanda Kafka & Console
    ├── minio/                 # MinIO S3 & Console
    ├── argocd/                # ArgoCD GitOps
    └── kubesphere/            # KubeSphere Core v4
```

---

## Additional Documentation

- **[Deployment Guide](docs/guides/deployment.md)** - Detailed step-by-step deployment
- **[Add Nodes Guide](docs/guides/add-nodes.md)** - Advanced node management
- **[Scripts Index](ansible/scripts/README.md)** - Scripts navigation
  - [K3s Scripts](ansible/k3s/scripts/README.md) - Cluster management
  - [ArgoCD Scripts](ansible/argocd/scripts/README.md) - GitOps deployment
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
5. **Scripts Organized** - Scripts organized by app: `ansible/k3s/scripts/`, `ansible/argocd/scripts/`

### 📌 Common Commands

```bash
# Initial setup
./k3s/scripts/bootstrap.sh

# Add workers
./k3s/scripts/add-node.sh node-2 node-3

# Deploy ArgoCD
./argocd/scripts/deploy-argocd.sh

# Remove a node
./k3s/scripts/remove-node.sh node-2

# Teardown cluster
./k3s/scripts/teardown.sh --all
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
