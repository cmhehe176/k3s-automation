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
./scripts/bootstrap.sh

# 3. Add workers
./scripts/add-node.sh node-2 node-3

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
| `scripts/bootstrap.sh` | Initialize cluster (control plane + storage + LoadBalancer) |
| `scripts/add-node.sh` | Add worker nodes |
| `scripts/remove-node.sh` | Remove specific node |
| `scripts/teardown.sh` | Flexible cluster teardown (all/specific/workers) |
| `scripts/deploy-argocd.sh` | Deploy ArgoCD GitOps |
| `scripts/uninstall-argocd.sh` | Remove ArgoCD |

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
│   ├── scripts/               # Management scripts
│   │   ├── bootstrap.sh
│   │   ├── add-node.sh
│   │   ├── remove-node.sh
│   │   ├── teardown.sh
│   │   └── ...
│   ├── inventory/             # Node configuration
│   ├── playbooks/             # Ansible playbooks
│   └── roles/                 # Ansible roles
└── docs/                      # Specialized documentation
    ├── operations/            # Security, requirements
    └── reference/             # Inventory config, troubleshooting
```

---

## 🎯 Common Operations

```bash
# Add new worker node
./scripts/add-node.sh node-4

# Deploy ArgoCD
./scripts/deploy-argocd.sh

# Remove a node
./scripts/remove-node.sh node-2

# Teardown entire cluster
./scripts/teardown.sh --all

# Teardown workers only
./scripts/teardown.sh --workers
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
