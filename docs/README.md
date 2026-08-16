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

**→ [Scripts Index](../ansible/scripts/README.md)** - Scripts navigation

Quick reference:
- K3s: `bootstrap.sh`, `add-node.sh`, `remove-node.sh`, `teardown.sh`
- ArgoCD: `deploy-argocd.sh`, `uninstall-argocd.sh`

**→ [K3s Scripts](../ansible/k3s/scripts/README.md)** - Cluster management  
**→ [ArgoCD Scripts](../ansible/argocd/scripts/README.md)** - GitOps deployment

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
→ [K3s Scripts - teardown.sh](../ansible/k3s/scripts/README.md#teardownsh)

**Deploy ArgoCD**  
→ [ArgoCD Scripts - deploy-argocd.sh](../ansible/argocd/scripts/README.md#deploy-argocdsh)

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
