# 🚀 K3s Cluster Automation

Automated K3s cluster deployment on bare-metal servers using Ansible.

---

## ⚡ Quick Start

```bash
# 1. Clone and configure
cd k3s-automation/ansible
nano inventory/hosts.ini          # Set node IPs
nano inventory/group_vars/all.yml # Set MetalLB IP range

# 2. Bootstrap cluster
./k3s/scripts/bootstrap.sh

# 3. Add workers
./k3s/scripts/add-node.sh node-2 node-3

# 4. Verify
export KUBECONFIG=~/.kube/config-k3s
kubectl get nodes
```

**→ [Complete Guide](COMPLETE_GUIDE.md)** - Full documentation

---

## 📚 Documentation

- **[COMPLETE_GUIDE.md](COMPLETE_GUIDE.md)** - Complete deployment & troubleshooting guide
- **[Scripts Reference](ansible/scripts/README.md)** - All management scripts
- **[Documentation Index](docs/README.md)** - Specialized topics (security, operations, reference)

---

## ✨ Key Features

- ✅ **Dual-purpose control plane** - Node-1 runs control + workloads
- ✅ **Automatic load balancing** - No taints, pods distributed evenly
- ✅ **Easy management** - Single commands to add/remove/teardown nodes
- ✅ **Production ready** - Longhorn storage, MetalLB LoadBalancer, ArgoCD
- ✅ **Tested** - Fedora 43 & Ubuntu 24.04

---

## 📋 Available Scripts

| Script | Purpose |
|--------|---------|
| `k3s/scripts/bootstrap.sh` | Initialize cluster (control plane + storage + LoadBalancer) |
| `k3s/scripts/add-node.sh` | Add worker nodes |
| `k3s/scripts/remove-node.sh` | Remove specific node |
| `k3s/scripts/teardown.sh` | Flexible cluster teardown (all/specific/workers) |
| `argocd/scripts/deploy-argocd.sh` | Deploy ArgoCD GitOps |
| `argocd/scripts/uninstall-argocd.sh` | Remove ArgoCD |

See [Scripts README](ansible/scripts/README.md) for detailed usage.

---

## 🏗️ What Gets Deployed

- **K3s v1.30.3** - Lightweight Kubernetes
- **Longhorn** - Distributed block storage
- **MetalLB** - LoadBalancer (L2 mode)
- **ArgoCD** - GitOps (optional)

**Architecture**: Control plane on node-1 (dual-purpose), workers on node-2+

---

## 📁 Repository Structure

```
k3s-automation/
├── COMPLETE_GUIDE.md          # Complete documentation
├── README.md                  # This file
├── ansible/
│   ├── inventory/             # Node configuration (shared)
│   ├── k3s/                   # K3s cluster core
│   │   ├── playbooks/         # K3s playbooks
│   │   ├── roles/             # K3s roles
│   │   └── scripts/           # Cluster management scripts
│   ├── argocd/                # ArgoCD GitOps
│   │   ├── playbooks/         # ArgoCD playbooks
│   │   ├── roles/             # ArgoCD role
│   │   └── scripts/           # ArgoCD management scripts
│   └── ansible.cfg            # Ansible configuration
└── docs/                      # Specialized documentation
    ├── operations/            # Security, requirements
    └── reference/             # Inventory config, troubleshooting
```

---

## 🎯 Common Operations

```bash
# Add new worker node
./k3s/scripts/add-node.sh node-4

# Deploy ArgoCD
./argocd/scripts/deploy-argocd.sh

# Remove a node
./k3s/scripts/remove-node.sh node-2

# Teardown entire cluster
./k3s/scripts/teardown.sh --all

# Teardown workers only
./k3s/scripts/teardown.sh --workers
```

---

## 🐛 Troubleshooting

See [COMPLETE_GUIDE.md - Troubleshooting](COMPLETE_GUIDE.md#troubleshooting) for:
- Common issues & fixes
- Pod scheduling problems
- LoadBalancer not assigning IPs
- Node not ready issues

---

## 📞 Support

**Documentation Issues**: Check [COMPLETE_GUIDE.md](COMPLETE_GUIDE.md) first  
**Bug Reports**: Open issue in repository  
**Maintainer**: Congminh  

---

**Version**: 2.0  
**Last Updated**: 2026-08-17  
**Status**: ✅ Production Ready
