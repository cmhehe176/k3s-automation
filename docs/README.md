# 📚 K3s Automation Documentation Hub

Welcome to the centralized documentation index for the K3s Automation project.

---

## 🚀 Guides

Step-by-step installation, operations, and troubleshooting walkthroughs:

- 📖 **[Complete Documentation Guide](guides/complete-guide.md)** — **Start here!** Full architectural breakdown, installation walkthrough, resource sizing, namespace topology, and common troubleshooting tips.
- 💻 **[CLI & TUI Management Guide](../ansible/scripts/README.md)** — Complete command reference for `./cluster.sh` (bootstrap, add-node, teardown, middleware, console).

---

## 🏗️ Architecture & Operations

In-depth technical decisions, prerequisites, and operational runbooks:

- ⚙️ **[System Requirements & Sizing](operations/requirements.md)** — Minimum hardware requirements, OS compatibility (Fedora/Ubuntu), CPU/RAM resource planning, and disk partitioning.
- 🔒 **[Security Hardening & Best Practices](operations/security.md)** — SSH key authentication, Ansible Vault encryption, sudo privilege separation, and Kubernetes RBAC.
- 💡 **[Architecture Brainstorming & Tradeoffs](operations/brainstorm.md)** — Evaluation notes comparing vanilla K8s, K3s, OKD, OpenShift Console Standalone, and KubeSphere Core.

---

## 📖 System Reference

Configuration details, inventory variables, and distribution-specific setup:

- 📝 **[Inventory & Group Variables](reference/inventory.md)** — Configuration reference for `hosts.ini`, `all.yml`, `k3s_control.yml`, and `k3s_workers.yml`.
- 🎩 **[Fedora / RHEL Specifics](reference/fedora-notes.md)** — NetworkManager, firewalld, SELinux, and cgroup v2 tuning on Fedora Core / Server.

---

## 🔍 Code Reviews & Security Audits

Historical and architectural audit reports:

- 📋 **[Code Quality Review](reviews/code-review.md)** — Comprehensive review of Ansible playbooks, role boundaries, and idempotency tests.
- 🛡️ **[Deep Security & Resilience Audit](reviews/deep-review.md)** — In-depth analysis of cluster recovery, firewall safety, token persistence, and failure recovery.

---

## 📦 Application Sub-Modules

Each middleware and platform service includes its own dedicated documentation:

- 🖥️ **[OpenShift Console & Dex OIDC](../ansible/openshift-console/README.md)** — Web console deployment, OAuth2/OIDC proxying, and multi-user login.
- 🗄️ **[Oracle Database](../ansible/oracle/README.md)** — Enterprise Oracle 19c/23ai single-instance deployment with Longhorn storage.
- ⚡ **[Redis Cluster](../ansible/redis/README.md)** — Highly available Redis Cluster with 16,384 hash slots across 6 pods.
- 🐼 **[Redpanda Kafka](../ansible/redpanda/README.md)** — Fast C++ Kafka-compatible streaming cluster and Redpanda Web Console.
- 🪣 **[MinIO S3 Storage](../ansible/minio/README.md)** — S3-compatible object storage server and web management UI.
- 🐙 **[ArgoCD](../ansible/argocd/scripts/README.md)** — GitOps continuous delivery platform.

---

**Maintainer**: Congminh  
**Version**: 2.0  
**Status**: ✅ Production Ready
