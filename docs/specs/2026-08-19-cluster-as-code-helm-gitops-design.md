# 📐 Design Specification: `cluster-as-code` (Helm-Driven GitOps with ArgoCD)

- **Date:** 2026-08-19
- **Status:** Approved
- **Target Location:** `/Users/congminh/pro/cluster-as-code`
- **Git Remote:** `https://git-ttcpdt.mbfs.vn/<group-or-user>/cluster-as-code.git`
- **Source Reference:** Inherits 100% components & parameters from `/Users/congminh/pro/k3s-automation`

---

## 🎯 1. Objectives & Architectural Scope

The goal is to build an independent, production-grade **Cluster-as-Code** GitOps repository based on Helm charts and ArgoCD "App of Apps" pattern to declare and manage the entire state of the K3s Kubernetes cluster:
1. **Multi-Tenancy & Governance:** Centralized management of Namespaces, ResourceQuotas, LimitRanges, RoleBindings, and NetworkPolicies.
2. **Cluster Core Services:** MetalLB Layer 2 LoadBalancer IP pools and Longhorn StorageClass definitions.
3. **Security & Management Console:** OpenShift Console 4.19 Standalone, Dex OIDC SSO (SQLite + PVC), RBAC bindings, and ConsoleLinks.
4. **Middleware Stack:** Oracle Database XE, Redis Cluster (6 nodes), Redpanda Kafka & Console, MinIO S3 Object Storage.
5. **Declarative Master Configuration:** Single master file `environments/production/values.yaml` controlling all cluster resources.

---

## 🏗️ 2. Repository Layout & Component Architecture

```text
cluster-as-code/
├── .gitignore
├── README.md
│
├── 00-bootstrap/                       # Master "App of Apps" Helm Chart
│   ├── Chart.yaml
│   ├── templates/
│   │   ├── 01-cluster-core-app.yaml    # Syncs charts/cluster-core
│   │   ├── 02-security-auth-app.yaml   # Syncs charts/security-auth
│   │   ├── 03-tenants-app.yaml         # Syncs charts/tenants-management
│   │   └── 04-middleware-app.yaml      # Syncs charts/middleware-stack
│   └── values.yaml
│
├── charts/
│   ├── cluster-core/                   # MetalLB & Storage
│   │   ├── Chart.yaml
│   │   ├── templates/
│   │   │   ├── metallb-ipaddresspool.yaml
│   │   │   └── metallb-l2advertisement.yaml
│   │   └── values.yaml
│   │
│   ├── tenants-management/             # Namespaces, Quotas & RBAC
│   │   ├── Chart.yaml
│   │   ├── templates/
│   │   │   ├── namespaces.yaml
│   │   │   ├── resource-quotas.yaml
│   │   │   ├── limit-ranges.yaml
│   │   │   └── role-bindings.yaml
│   │   └── values.yaml
│   │
│   ├── security-auth/                  # OpenShift Console & Dex OIDC
│   │   ├── Chart.yaml
│   │   ├── templates/
│   │   │   ├── dex.yaml
│   │   │   ├── openshift-console.yaml
│   │   │   ├── rbac.yaml
│   │   │   └── console-links.yaml
│   │   └── values.yaml
│   │
│   └── middleware-stack/               # Oracle, Redis, Redpanda, MinIO
│       ├── Chart.yaml
│       ├── templates/
│       │   ├── oracle.yaml
│       │   ├── redis-cluster.yaml
│       │   ├── redpanda.yaml
│       │   └── minio.yaml
│       └── values.yaml
│
└── environments/
    └── production/
        └── values.yaml                 # Master Values File
```

---

## 📋 3. Component Details Inherited from `k3s-automation`

| Component | Namespace | Storage / Strategy | Network Ports / LoadBalancer |
| :--- | :--- | :--- | :--- |
| **MetalLB** | `metallb-system` | N/A | Pool: `10.200.10.1-10.200.10.250` (L2 ARP) |
| **Dex OIDC** | `openshift-console` | Longhorn PVC `dex-data` (1Gi, RWO, `strategy: Recreate`) | `5556` (NodePort `32000`) |
| **OpenShift Console** | `openshift-console` | OIDC Auth via Dex | `9000` (NodePort `30900`) |
| **Oracle Database** | `oracle` | Longhorn PVC `oracle-pvc` (30Gi, RWO, `strategy: Recreate`) | `1521` (NodePort `31521`, LB `10.200.10.4`) |
| **Redis Cluster** | `redis` | Longhorn PVC (6 Pods, 16,384 slots) | `6379` (NodePort `31379`, LB `10.200.10.5`) |
| **Redpanda Kafka** | `redpanda` | Longhorn PVC `redpanda-data` | `9092:31092` (Kafka), `8080:31080` (Console) |
| **MinIO S3** | `minio` | Longhorn PVC `minio-pvc` (40Gi, RWO, `strategy: Recreate`) | `9000:31900` (S3 API), `9001:31901` (Console) |
| **ArgoCD** | `argocd` | GitOps Control Plane | `443:30887` (LB `10.200.10.8`) |

---

## 🚀 4. GitOps Workflow

1. Push repo to `https://git-ttcpdt.mbfs.vn/<group>/cluster-as-code.git`.
2. Apply `00-bootstrap/` to ArgoCD in the cluster.
3. ArgoCD automatically deploys and continuously reconciles all 4 sub-charts.
4. Any commit to `environments/production/values.yaml` triggers an automated zero-downtime cluster sync.
