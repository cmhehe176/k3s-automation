# 🚀 ArgoCD Management Scripts

Scripts for ArgoCD GitOps deployment and management.

---

## 📋 Available Scripts

### `deploy-argocd.sh`
Deploy ArgoCD to the cluster.

```bash
./argocd/scripts/deploy-argocd.sh
```

**What it does:**
1. Create argocd namespace
2. Deploy ArgoCD v2.12.0
3. Configure LoadBalancer service
4. Display access credentials

**Post-deployment:**
After successful deployment, you'll receive:
- ArgoCD UI LoadBalancer IP
- Admin password
- Instructions for accessing and configuring ArgoCD

---

### `uninstall-argocd.sh`
Remove ArgoCD from the cluster.

```bash
./argocd/scripts/uninstall-argocd.sh
```

**What it does:**
1. Delete all ArgoCD applications
2. Remove ArgoCD namespace
3. Clean up resources

**Warning:** This will remove all ArgoCD applications and their configurations. Make sure to backup any important application definitions before uninstalling.

---

## 🚀 Common Workflows

### Deploy ArgoCD
```bash
cd ansible/

# Deploy ArgoCD
./argocd/scripts/deploy-argocd.sh

# Access UI at the displayed LoadBalancer IP
# Login with username: admin
# Password: (displayed in output)
```

### Configure First Application
```bash
# After deployment, configure your first app
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/your-repo
    targetRevision: HEAD
    path: k8s/
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
```

### Uninstall ArgoCD
```bash
# When you need to remove ArgoCD
./argocd/scripts/uninstall-argocd.sh
```

---

## 📋 Prerequisites

All scripts must be run from the `ansible/` directory:

```bash
cd /path/to/k3s-automation/ansible
./argocd/scripts/<script-name>.sh
```

**Requirements:**
- K3s cluster already running
- Ansible installed
- SSH access to control node
- Inventory file configured (`inventory/hosts.ini`)

---

## 🔗 Related Documentation

- [ArgoCD Official Docs](https://argo-cd.readthedocs.io/)
- [K3s Bootstrap](../k3s/scripts/README.md) - Setup K3s cluster first

---

**Last Updated**: 2026-08-16  
**Maintainer**: Congminh
