# 📚 K3s Automation Documentation

**Version**: 2.0  
**Last Updated**: 2026-08-17

---

## 📖 Main Documentation

### 🚀 Getting Started

**→ [COMPLETE_GUIDE.md](../COMPLETE_GUIDE.md)** - **START HERE!**

Comprehensive guide covering:
- Quick start (5 minutes to running cluster)
- Architecture overview
- All scripts usage (bootstrap, add-node, teardown, ArgoCD)
- Pod scheduling & load balancing
- Troubleshooting
- Complete examples

**→ [Scripts Reference](../ansible/scripts/README.md)** - All management scripts

Quick reference for:
- `bootstrap.sh` - Initialize cluster
- `add-node.sh` - Add workers
- `remove-node.sh` - Remove nodes
- `teardown.sh` - Flexible teardown
- `deploy-argocd.sh` - ArgoCD GitOps

---

## 📂 Specialized Documentation

### Operations

- **[Requirements](operations/requirements.md)** - System requirements and prerequisites
- **[Security](operations/security.md)** - Security best practices and hardening
- **[Brainstorm](operations/brainstorm.md)** - Architecture decisions and design notes
- **[Code Review](operations/code-review.md)** - Code review findings

### Reference

- **[Inventory Configuration](reference/inventory.md)** - Ansible inventory setup
- **[Fedora Notes](reference/fedora-notes.md)** - Fedora-specific configurations

---

## 🎯 Quick Navigation

### I want to...

**Deploy a new cluster**  
→ [COMPLETE_GUIDE.md - Quick Start](../COMPLETE_GUIDE.md#quick-start)

**Add worker nodes**  
→ [COMPLETE_GUIDE.md - Cluster Management](../COMPLETE_GUIDE.md#cluster-management)

**Remove nodes or teardown**  
→ [Scripts README - teardown.sh](../ansible/scripts/README.md#teardownsh)

**Deploy ArgoCD**  
→ [Scripts README - deploy-argocd.sh](../ansible/scripts/README.md#deploy-argocdsh)

**Troubleshoot issues**  
→ [COMPLETE_GUIDE.md - Troubleshooting](../COMPLETE_GUIDE.md#troubleshooting)

**Understand pod scheduling**  
→ [COMPLETE_GUIDE.md - Pod Scheduling](../COMPLETE_GUIDE.md#pod-scheduling--load-balancing)

---

## 📌 Key Concepts

### No Taints by Default

All nodes accept pods automatically. Kubernetes scheduler distributes workloads evenly across all nodes without requiring tolerations.

### Dual-Purpose Control Plane

Node-1 runs both control plane components AND application workloads. No wasted resources.

### Automatic Load Balancing

Pods are distributed based on available resources. No manual intervention needed.

---

## 🔗 External Resources

- [K3s Official Docs](https://docs.k3s.io/)
- [Longhorn Documentation](https://longhorn.io/docs/)
- [MetalLB Documentation](https://metallb.universe.tf/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)

---

**Maintainer**: Congminh  
**Repository**: `cicd-ndc/k3s-automation`  
**Version**: 2.0
