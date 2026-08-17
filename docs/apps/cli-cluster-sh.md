# 🔧 Ansible Management Scripts & Unified CLI

To simplify operations across K3s, ArgoCD, and KubeSphere, use the unified master wrapper script: **[`./cluster.sh`](../cluster.sh)**.

---

## 🚀 Unified Cluster Manager: `./cluster.sh`

Run `./cluster.sh` directly from the `ansible/` root directory.

### Interactive Menu Mode
Simply run `./cluster.sh` without arguments to open the interactive TUI:
```bash
./cluster.sh
```

```text
================================================================
          🚀 K3S CLUSTER AUTOMATION MANAGER
================================================================

Select an operation:

  1) 🎯 Bootstrap Control Plane (Node-1)
  2) ➕ Add Worker Node(s)
  3) ➖ Remove Worker Node
  4) 📊 Cluster Status & Health Check
  5) 💾 Backup Cluster
  6) 🔄 Restore Cluster
  7) 🐙 ArgoCD (Deploy / Uninstall)
  8) 🌐 KubeSphere (Deploy / Uninstall)
  9) 🗑️  Teardown Entire Cluster
  0) ❌ Exit

Enter choice [0-9]: 
```

---

### Command Line Interface (CLI) Mode

| Action | Command |
|---|---|
| **Bootstrap Cluster** | `./cluster.sh bootstrap [node-1]` |
| **Add Worker Nodes** | `./cluster.sh add-node node-2 [node-3 ...]` |
| **Remove Worker Node** | `./cluster.sh remove-node node-2` |
| **Health Check & Pods** | `./cluster.sh status` |
| **Backup Cluster** | `./cluster.sh backup` |
| **Restore Cluster** | `./cluster.sh restore <backup-file>` |
| **Deploy ArgoCD** | `./cluster.sh argocd deploy` |
| **Uninstall ArgoCD** | `./cluster.sh argocd uninstall` |
| **Deploy KubeSphere** | `./cluster.sh kubesphere deploy` |
| **Uninstall KubeSphere**| `./cluster.sh kubesphere uninstall` |
| **Teardown All** | `./cluster.sh teardown --all` |

---

## 📁 Component Scripts

Behind the scenes, `./cluster.sh` wraps the application-specific scripts:

- **[k3s/scripts/](../k3s/scripts/)**:
  - `bootstrap.sh` - Prerequisites + K3s server setup + Addons
  - `add-node.sh` - Worker join with standard/flexible limits
  - `remove-node.sh` - Drain, delete, and teardown single worker node
  - `teardown.sh` - Complete purge & cleanup
  - `backup.sh` / `restore.sh` - Etcd snapshots and cluster state
- **[argocd/scripts/](../argocd/scripts/)**: `deploy-argocd.sh`, `uninstall-argocd.sh`
- **[kubesphere/scripts/](../kubesphere/scripts/)**: `deploy-kubesphere.sh`, `uninstall-kubesphere.sh`
