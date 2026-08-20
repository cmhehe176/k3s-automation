# 🚀 K3s Cluster Automation

Automated, production-ready K3s Kubernetes cluster deployment and complete enterprise middleware stack on bare-metal / VPS servers using Ansible.

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

**→ [Complete Documentation Guide](docs/guides/complete-guide.md)** — Bắt đầu từ đây để xem tài liệu toàn tập!

---

## ✨ Key Features

- ✅ **Dual-Purpose Control Plane** — Master node runs control plane and workloads seamlessly (no taints).
- ✅ **Multi-Distro OS Support** — Tự động hỗ trợ Ubuntu, Debian, Fedora, RedHat, Rocky Linux, AlmaLinux.
- ✅ **Multi-Mirror Fallback Architecture** — Zero-failure manifest downloads với local fallback bundles đóng gói sẵn.
- ✅ **Complete Enterprise Middleware** — Oracle Database 19c/23ai, Redis Cluster, Redpanda Kafka, MinIO S3.
- ✅ **Red Hat OpenShift Console** — Standalone web dashboard với Dex OIDC & multi-user RBAC.
- ✅ **Unified CLI & Interactive TUI** — Script `./cluster.sh` điều khiển toàn bộ vòng đời cluster.
- ✅ **Idempotent & Safe Teardown** — Dọn dẹp sạch sẽ, bảo toàn 100% luật SSH và tường lửa hệ thống.

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
| `logging` | Observability | ECK Operator, Elasticsearch, Kibana, APM, Vector | NodePort `30601`, Port `8200`, `9200` |
| `argocd` | GitOps | ArgoCD Server & Controller | NodePort / LB |

---

## 📚 Central Documentation Hub (`docs/`)

Toàn bộ tài liệu, hướng dẫn và ghi chú kỹ thuật được lưu trữ duy nhất tại thư mục **[`docs/`](docs/README.md)**:

- 📖 **[Complete Guide](docs/guides/complete-guide.md)** — Tài liệu hướng dẫn toàn diện từ A-Z
- 📦 **[Application Docs](docs/README.md#2-application--middleware-guides-docsapps)** — Hướng dẫn chi tiết từng app ([OpenShift Console](docs/apps/openshift-console.md), [Oracle](docs/apps/oracle.md), [Redis](docs/apps/redis.md), [Redpanda](docs/apps/redpanda.md), [MinIO](docs/apps/minio.md), [Logging Stack](docs/apps/logging.md), [ArgoCD](docs/apps/argocd.md), [CLI Manager](docs/apps/cli-cluster-sh.md))
- 💻 **[Client Machine Setup](docs/operations/client-setup.md)** — Cài đặt Ansible và công cụ trên máy client / laptop
- 🔒 **[RBAC & Permissions Guide](docs/operations/rbac-and-permissions.md)** — Hướng dẫn phân quyền User/Group trên CLI và OpenShift Console
- 📦 **[ConfigMaps & Secrets Reference](docs/reference/configmaps-and-secrets.md)** — Kiến trúc tham số động, danh mục ConfigMaps & Secrets
- 🔒 **[Security Hardening](docs/operations/security.md)** — Bảo mật SSH, Ansible Vault, sudo và RBAC
- ⚙️ **[System Requirements](docs/operations/requirements.md)** — Yêu cầu phần cứng, hệ điều hành và định cỡ tài nguyên
- 📝 **[Inventory & Variables](docs/reference/inventory.md)** — Cấu hình biến Ansible
- 🔍 **[Code Review & Audits](docs/reviews/code-review.md)** — Báo cáo chất lượng code và audit bảo mật
- 📐 **[Design Specs & Plans](docs/README.md#6-specs--plans-docsspecs--docsplans)** — Các bản thiết kế và kế hoạch chi tiết

---

**Maintainer**: Congminh  
**Version**: 2.0  
**Status**: ✅ Production Ready
