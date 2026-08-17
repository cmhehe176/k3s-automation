# 🚀 K3s Cluster Automation

Automated, production-ready K3s Kubernetes cluster deployment and complete middleware stack on bare-metal / VPS servers using Ansible.

---

## ⚡ Quick Start

```bash
# 1. Configure cluster inventory
cd ansible
nano inventory/hosts.ini          # Set node IPs and SSH users
nano inventory/group_vars/all.yml # Set MetalLB IP range / tokens

# 2. Deploy everything using the master CLI wrapper
./cluster.sh bootstrap           # Bootstrap K3s, MetalLB, Longhorn
./cluster.sh middleware deploy   # Deploy Oracle, Redis, Redpanda, MinIO
./cluster.sh console deploy      # Deploy OpenShift Console + Dex OIDC

# 3. Or use the interactive terminal UI
./cluster.sh
```

**→ [Complete Documentation Guide](docs/guides/complete-guide.md)** — Start here for full details!

---

## ✨ Key Features

- ✅ **Dual-Purpose Control Plane** — Master node runs control plane and workloads seamlessly (no taints).
- ✅ **Multi-Mirror Fallback Architecture** — Zero-failure manifest downloads with local fallback bundles.
- ✅ **Complete Enterprise Middleware** — Oracle Database, Redis Cluster, Redpanda Kafka, MinIO S3.
- ✅ **Red Hat OpenShift Console** — Standalone web dashboard with Dex OIDC & multi-user RBAC.
- ✅ **Unified CLI & Interactive TUI** — Single `./cluster.sh` script to manage the entire lifecycle.
- ✅ **Idempotent & Safe Teardown** — Non-destructive cleanup that preserves system firewall & SSH connectivity.

---

## 🏗️ Architecture & Workload Isolation

Every system component and workload runs in a dedicated namespace with persistent storage on Longhorn:

| Namespace | Category | Component | Ports / Access |
|---|---|---|---|
| `kube-system` | Core | K3s Core, CoreDNS, Flannel CNI | Port 6443 |
| `metallb-system` | Network | MetalLB L2 LoadBalancer | IP Pool |
| `longhorn-system` | Storage | Longhorn Distributed Block Storage CSI | In-cluster |
| `openshift-console` | Management | OpenShift Web Console & Dex OIDC | NodePort `30900`, `32000` |
| `oracle` | Database | Oracle Database 19c/23ai | NodePort `31521` |
| `redis` | Cache | Redis Cluster (16,384 Hash Slots) | NodePort `31379` |
| `redpanda` | Streaming | Redpanda Kafka & Web Console | NodePort `31092`, `31080` |
| `minio` | Object Store | MinIO S3 API & Web Console | NodePort `31900`, `31901` |
| `argocd` | GitOps | ArgoCD Server & Controller | NodePort / LB |

---

## 📁 Repository Structure

```
k3s-automation/
├── cluster.sh                 # Root executable CLI wrapper
├── README.md                  # This landing page
├── docs/                      # Centralized documentation hub
│   ├── README.md              # Documentation navigation index
│   ├── guides/                # Step-by-step guides (complete-guide.md, etc.)
│   ├── operations/            # Requirements, security, brainstorm
│   ├── reference/             # Inventory reference, Fedora/RHEL notes
│   └── reviews/               # Code reviews & security audits
└── ansible/                   # Automation engine
    ├── cluster.sh             # Master CLI & TUI engine
    ├── inventory/             # Node hosts & group variables
    ├── k3s/                   # Core K3s, MetalLB, Longhorn, Teardown
    ├── openshift-console/     # OpenShift Console & Dex OIDC
    ├── oracle/                # Oracle Database 19c/23ai
    ├── redis/                 # Redis Cluster (6 nodes)
    ├── redpanda/              # Redpanda Kafka & Console
    ├── minio/                 # MinIO S3 & Web Console
    ├── argocd/                # ArgoCD GitOps
    └── kubesphere/            # KubeSphere Core v4
```

---

## 📚 Documentation Index

For in-depth guides and references, check the `docs/` directory:

- 📖 **[Complete Guide](docs/guides/complete-guide.md)** — Full cluster guide & troubleshooting
- 🛠️ **[CLI Reference](ansible/scripts/README.md)** — All `cluster.sh` subcommands
- 🖥️ **[OpenShift Console & Dex Guide](ansible/openshift-console/README.md)** — Web console & OIDC setup
- 🔒 **[Security Hardening](docs/operations/security.md)** — SSH, Vault, and RBAC best practices
- ⚙️ **[System Requirements](docs/operations/requirements.md)** — Hardware sizing & OS prerequisites
- 🔍 **[Code Review & Audit Reports](docs/reviews/code-review.md)** — Audit analysis & improvements

---

**Maintainer**: Congminh  
**Version**: 2.0  
**Status**: ✅ Production Ready
