# 📚 K3s Automation Documentation Hub

> **Duy nhất một nơi lưu trữ toàn bộ tài liệu & ghi chú của dự án K3s Automation.**

---

## 🚀 1. Guides & Hướng Dẫn Vận Hành

- 📖 **[Complete Documentation Guide](guides/complete-guide.md)** — **Tài liệu toàn tập (Bắt đầu từ đây)**: Kiến trúc tổng quan, hướng dẫn triển khai từ A-Z, cấu hình tài nguyên, phân chia namespace, và xử lý sự cố.

---

## 📦 2. Application & Middleware Guides (`docs/apps/`)

Hướng dẫn chi tiết từng dịch vụ ứng dụng và middleware trong cluster:

- 🖥️ **[OpenShift Console & Dex OIDC](apps/openshift-console.md)** — Giao diện Web Console OpenShift, tích hợp xác thực Dex OIDC Web Form, phân quyền Multi-User RBAC.
- 🗄️ **[Oracle Database XE](apps/oracle.md)** — Triển khai Oracle Database 19c/23ai với Persistent Storage trên Longhorn, port `31521`.
- ⚡ **[Redis Cluster](apps/redis.md)** — Cụm Redis Cluster phân bổ 16,384 Hash Slots qua 6 pods, port `31379`.
- 🐼 **[Redpanda Kafka & Console](apps/redpanda.md)** — Cụm Streaming Kafka tốc độ cao bằng C++ kèm giao diện Redpanda Web Console, port `31092` & `31080`.
- 🪣 **[MinIO S3 Object Storage](apps/minio.md)** — Hệ thống lưu trữ S3 Object Storage hiệu năng cao kèm Web Console, port `31900` & `31901`.
- 🪵 **[Production Logging Stack](apps/logging.md)** — Cụm ECK Operator, Elasticsearch 9.5.0 (3 nodes), Kibana Web Console, APM Server & Vector log processing.
- 🐙 **[ArgoCD GitOps](apps/argocd.md)** — Nền tảng GitOps Continuous Delivery tích hợp MetalLB LoadBalancer.
- 💻 **[CLI & Interactive TUI Manager](apps/cli-cluster-sh.md)** — Hướng dẫn toàn diện sử dụng script điều khiển `./cluster.sh`.
- 🛠️ **[K3s Management Scripts](apps/k3s-scripts.md)** — Các script vận hành K3s core (`bootstrap.sh`, `add-node.sh`, `remove-node.sh`, `teardown.sh`).

---

## 🏗️ 3. Operations & Kiến Trúc (`docs/operations/`)

- 💻 **[Client Machine Setup](operations/client-setup.md)** — Cài đặt và cấu hình Ansible Controller trên macOS, Linux, Windows WSL.
- 🔒 **[RBAC & User Permissions Guide](operations/rbac-and-permissions.md)** — Hướng dẫn toàn diện phân quyền User/Group (`edit`, `view`, `admin`) trên CLI và Web Console.
- ⚙️ **[System Requirements & Sizing](operations/requirements.md)** — Yêu cầu phần cứng tối thiểu, hỗ trợ đa hệ điều hành (Ubuntu, Debian, Fedora, RedHat, Rocky, Alma), tính toán RAM/CPU.
- 🔒 **[Security Hardening & Best Practices](operations/security.md)** — Bảo mật SSH key, Ansible Vault encryption, phân quyền sudo, và Kubernetes RBAC.
- 💡 **[Architecture Brainstorming & Tradeoffs](operations/brainstorm.md)** — Ghi chú so sánh kiến trúc giữa Vanilla K8s, K3s, OKD, OpenShift Console Standalone, và KubeSphere Core.

---

## 📖 4. Reference & Cấu Hình (`docs/reference/`)

- 📝 **[Inventory & Variables Reference](reference/inventory.md)** — Tham chiếu chi tiết file `hosts.ini`, `all.yml`, `k3s_control.yml`, và `k3s_workers.yml`.
- 📦 **[ConfigMaps & Secrets Reference](reference/configmaps-and-secrets.md)** — Kiến trúc giải phóng tham số động, danh mục ConfigMaps & Secrets cho toàn bộ ứng dụng.
- 🎩 **[Fedora / RHEL Specifics](reference/fedora-notes.md)** — Lưu ý và tinh chỉnh riêng cho Fedora Core / Server (SELinux, firewalld, cgroup v2).

---

## 🔍 5. Audits & Code Reviews (`docs/reviews/`)

- 📋 **[Code Quality Review](reviews/code-review.md)** — Đánh giá chi tiết chất lượng code, cấu trúc Ansible Playbooks/Roles, và tính Idempotency.
- 🛡️ **[Deep Security & Resilience Audit](reviews/deep-review.md)** — Đánh giá chuyên sâu về an toàn tường lửa, bảo vệ kết nối SSH khi Teardown, và khả năng phục hồi dữ liệu.

---

## 📐 6. Specs & Plans (`docs/specs/` & `docs/plans/`)

- 📑 **[OpenShift Console & Dex OIDC Spec](specs/2026-08-17-openshift-console-dex-oidc-design.md)** — Bản đặc tả thiết kế kiến trúc OpenShift Console Standalone.
- 📋 **[K3s Middleware Stack Plan](plans/2026-08-17-k3s-middleware-stack.md)** — Kế hoạch triển khai cụm Middleware (Oracle, Redis, Redpanda, MinIO).
- 📋 **[KubeSphere Core Plan](plans/kubesphere-simple.md)** — Kế hoạch triển khai KubeSphere Core v4.
- 📋 **[OKD Exploration Plan](plans/okd-deployment.md)** — Khảo sát và so sánh OKD vs K3s.
- 📋 **[Ansible Refactoring Plan](plans/refactor-ansible-structure.md)** — Kế hoạch tái cấu trúc Ansible theo ứng dụng.

---

**Maintainer**: Congminh  
**Version**: 2.0  
**Status**: ✅ Production Ready
