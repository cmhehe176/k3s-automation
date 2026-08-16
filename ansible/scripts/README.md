# 🔧 Ansible Management Scripts

Scripts are organized by application for better maintainability and scalability.

---

## 📁 Script Organization

Each application has its own scripts directory:

- **[k3s/scripts/](../k3s/scripts/)** - K3s cluster management (bootstrap, nodes, teardown)
- **[argocd/scripts/](../argocd/scripts/)** - ArgoCD GitOps deployment

---

## 🚀 Quick Navigation

### K3s Cluster Management

| Script | Purpose |
|--------|---------|
| [k3s/scripts/bootstrap.sh](../k3s/scripts/README.md#bootstrapsh) | Initialize cluster |
| [k3s/scripts/add-node.sh](../k3s/scripts/README.md#add-nodesh) | Add worker nodes |
| [k3s/scripts/remove-node.sh](../k3s/scripts/README.md#remove-nodesh) | Remove specific node |
| [k3s/scripts/teardown.sh](../k3s/scripts/README.md#teardownsh) | Teardown cluster |

**→ [Full K3s Scripts Documentation](../k3s/scripts/README.md)**

### ArgoCD Management

| Script | Purpose |
|--------|---------|
| [argocd/scripts/deploy-argocd.sh](../argocd/scripts/README.md#deploy-argocdsh) | Deploy ArgoCD |
| [argocd/scripts/uninstall-argocd.sh](../argocd/scripts/README.md#uninstall-argocdsh) | Remove ArgoCD |

**→ [Full ArgoCD Scripts Documentation](../argocd/scripts/README.md)**

---

## 📖 Usage

All scripts must be run from the `ansible/` directory:

```bash
cd /path/to/k3s-automation/ansible
./k3s/scripts/<script-name>.sh
./argocd/scripts/<script-name>.sh
```

---

## 🎯 Common Workflow

```bash
cd ansible/

# 1. Bootstrap K3s cluster
./k3s/scripts/bootstrap.sh

# 2. Add worker nodes
./k3s/scripts/add-node.sh node-2 node-3

# 3. Deploy ArgoCD (optional)
./argocd/scripts/deploy-argocd.sh

# 4. Verify
export KUBECONFIG=~/.kube/config-k3s
kubectl get nodes
kubectl get pods -A
```

---

## 🔮 Adding New Applications

When adding new applications (e.g., Prometheus, Grafana):

```bash
# Create directory structure
mkdir -p <app-name>/{playbooks,roles,scripts}

# Add scripts with documentation
# Update ansible.cfg roles_path
# Create <app-name>/scripts/README.md
```

Example structure:
```
ansible/
├── k3s/
├── argocd/
└── prometheus/         # New app
    ├── playbooks/
    ├── roles/
    └── scripts/
        └── README.md   # App-specific docs
```

---

## 📋 Prerequisites

- Ansible installed
- SSH access to all target nodes
- `kubectl` installed (for cluster operations)
- Inventory file configured (`inventory/hosts.ini`)

---

## 🔗 Related Documentation

- [Complete Deployment Guide](../../../COMPLETE_GUIDE.md)
- [Inventory Configuration](../../docs/reference/inventory.md)

---

**Last Updated**: 2026-08-16  
**Maintainer**: Congminh
