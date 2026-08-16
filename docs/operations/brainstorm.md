# 🧠 K3s Cluster Design Brainstorming

**Session Date**: 2026-08-16  
**Goal**: Thiết kế chi tiết K3s cluster infrastructure cho NDC microservices

---

## 🎯 Mục Tiêu Hệ Thống

### Business Requirements
- Host 3 microservice projects: **DVC**, **PAKN**, **Thanh Toán**
- Mỗi project có 2 domains: `backend` (core) và `dmz` (frontend)
- Hỗ trợ 3 environments: **dev**, **stg**, **prod**
- High availability cho production workloads
- Cost-effective với hardware hiện có (3 Nodes)
- Middleware stack: **Oracle Database**, **Kafka**, **Redis**, **NATS**

### Technical Requirements
- Container orchestration với K3s (lightweight Kubernetes)
- Distributed storage cho stateful apps
- LoadBalancer cho external access
- CI/CD integration với Jenkins pipeline hiện có
- GitOps workflow với ArgoCD (đã có sẵn)

---

## 🏗️ Kiến Trúc Hiện Tại (Baseline)

### Hardware Resources
```
┌─────────────────────────────────────────────────────────────┐
│                    3-Node Physical Setup                     │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  Node-1 (192.168.1.10)        Node-2 (192.168.1.11)             │
│  ┌──────────────────┐       ┌──────────────────┐            │
│  │ K3s Control +    │       │ K3s Worker       │            │
│  │ Worker Node      │───────│ Node             │            │
│  │                  │       │                  │            │
│  │ 32GB RAM         │       │ 32GB RAM         │            │
│  │ 1TB Disk         │       │ 1TB Disk         │            │
│  └──────────────────┘       └──────────────────┘            │
│                                                               │
│  Node-3 (192.168.1.12)                                         │
│  ┌──────────────────────────────────────┐                   │
│  │ Middleware Node                      │                   │
│  │ - Oracle Database 19c                │                   │
│  │ - Kafka + ZooKeeper                  │                   │
│  │ - Redis                              │                   │
│  │ - NATS                               │                   │
│  │                                      │                   │
│  │ 32GB RAM / 1TB Disk                  │                   │
│  └──────────────────────────────────────┘                   │
└─────────────────────────────────────────────────────────────┘
```

### Vấn Đề Cần Giải Quyết

**🔴 Single Point of Failure**
- Chỉ có 1 control plane node (Node-1)
- Nếu Node-1 chết → toàn bộ cluster down

**🟡 Resource Allocation**
- Cần phân bổ RAM/CPU hợp lý cho từng service
- 3 projects × 2 domains × 3 envs = tối đa 18 deployments

**🟡 Storage Strategy**
- Stateless apps (frontend, backend APIs): ephemeral storage OK
- Stateful apps (nếu có): cần persistent volumes
- Database layer: nên tách riêng hay chạy trong K3s?

**🟢 Networking**
- LoadBalancer IPs cho external access
- Service mesh hay simple ingress?

---

## 💡 Design Options & Tradeoffs

### Option 1: Pure K3s Cluster (Tất Cả Trong K3s)

```
┌─────────────────────────────────────────────────────────┐
│              2-Node K3s Cluster                          │
│  ┌──────────────────┐       ┌──────────────────┐        │
│  │ Node-1 (Control)   │       │ Node-2 (Worker)    │        │
│  └──────────────────┘       └──────────────────┘        │
│                                                           │
│  Workloads:                                              │
│  ├─ Applications (DVC/PAKN/ThanhToan)                    │
│  ├─ Oracle Database (StatefulSet + Longhorn) - optional │
│  ├─ Kafka (StatefulSet) - optional                      │
│  ├─ Redis (StatefulSet)                                  │
│  └─ NATS (StatefulSet)                                   │
│                                                           │
│  Node-3: BACKUP NODE hoặc NFS server                       │
└─────────────────────────────────────────────────────────┘
```

**✅ Pros:**
- Quản lý tập trung với kubectl
- Auto-scaling, self-healing cho middleware
- Longhorn replicated storage (backup giữa Node-1 và Node-2)
- ArgoCD có thể manage toàn bộ stack

**❌ Cons:**
- Database performance có thể kém hơn bare-metal
- Phức tạp hơn cho troubleshooting DB issues
- Overhead của Kubernetes cho middleware

**🎯 Best For:** Team muốn fully cloud-native, đã quen với K8s operators

---

### Option 2: Hybrid Setup (Đang Dùng)

```
┌─────────────────────────────────────────────────────────┐
│         2-Node K3s Cluster (Applications Only)           │
│  ┌──────────────────┐       ┌──────────────────┐        │
│  │ Node-1 (Control)   │       │ Node-2 (Worker)    │        │
│  └──────────────────┘       └──────────────────┘        │
│                                                           │
│  Workloads:                                              │
│  └─ Applications (DVC/PAKN/ThanhToan x 3 envs)           │
│                                                           │
│  ┌──────────────────────────────────────────────┐        │
│  │ Node-3 (Bare-Metal Middleware)                 │        │
│  ├─ Oracle Database 19c (Native install)        │        │
│  ├─ Kafka + ZooKeeper (Native install)          │        │
│  ├─ Redis (Native install)                      │        │
│  └─ NATS (Native install)                       │        │
│                                                           │
│  Apps connect to Node-3 via Service ExternalName           │
└─────────────────────────────────────────────────────────┘
```

**✅ Pros:**
- Database performance tối ưu (bare-metal)
- Dễ troubleshoot và backup database
- Tách biệt concerns: K3s cho apps, Node-3 cho data
- Ít overhead hơn

**❌ Cons:**
- Quản lý 2 layers riêng biệt (K3s + bare-metal)
- Middleware không có auto-scaling
- Node-3 là SPOF cho database layer

**🎯 Best For:** Team ưu tiên DB performance, đã có kinh nghiệm quản lý database truyền thống

---

### Option 3: HA K3s Cluster (3-Node Control Plane)

```
┌─────────────────────────────────────────────────────────┐
│              3-Node HA K3s Cluster                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Node-1         │  │ Node-2         │  │ Node-3         │  │
│  │ Control +    │  │ Control +    │  │ Control +    │  │
│  │ Worker       │  │ Worker       │  │ Worker       │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│                                                           │
│  - Etcd HA (3 members quorum)                            │
│  - No single point of failure                            │
│  - Middleware chạy trong cluster                         │
└─────────────────────────────────────────────────────────┘
```

**✅ Pros:**
- True high availability
- Không có SPOF
- Control plane có thể chịu được 1 node failure

**❌ Cons:**
- Phức tạp nhất
- Tốn nhiều resources (3 control planes)
- Overkill cho dev/stg environments

**🎯 Best For:** Production-critical systems, SLA yêu cầu cao

---

## 🎲 Recommended Architecture

### **Option 2 (Hybrid)** - RECOMMENDED

**Rationale:**
1. **Separation of Concerns**: Apps và data layer tách biệt
2. **Performance**: Database chạy bare-metal, không bị overhead K8s
3. **Simplicity**: Đơn giản hơn Option 3, practical hơn Option 1
4. **Cost**: Tận dụng tối đa 3 Nodes hiện có
5. **Migration Path**: Dễ migrate sang Option 1 sau nếu cần

### Detailed Design

#### K3s Layer (Node-1 + Node-2)

**Control Plane (Node-1)**
```yaml
Role: k3s server + worker
Resources Allocated:
  - System: 4GB RAM, 2 CPU
  - K3s: 2GB RAM, 1 CPU
  - Applications: 26GB RAM, 29 CPU available

Disabled Components:
  - traefik (dùng nginx-ingress)
  - servicelb (dùng MetalLB)
```

**Worker (Node-2)**
```yaml
Role: k3s agent
Resources Allocated:
  - System: 4GB RAM, 2 CPU
  - K3s: 1GB RAM, 1 CPU
  - Applications: 27GB RAM, 29 CPU available
```

**Total Cluster Capacity**
- **RAM**: ~53GB cho applications
- **CPU**: ~58 cores
- **Storage**: 2TB distributed (Longhorn replication 2)

#### Application Resource Allocation

**Per Microservice (Backend/DMZ):**
```yaml
# Dev Environment (thấp nhất)
requests:
  memory: 512Mi
  cpu: 100m
limits:
  memory: 1Gi
  cpu: 500m

# Staging Environment
requests:
  memory: 1Gi
  cpu: 250m
limits:
  memory: 2Gi
  cpu: 1000m

# Production Environment
requests:
  memory: 2Gi
  cpu: 500m
limits:
  memory: 4Gi
  cpu: 2000m
```

**Capacity Planning:**
```
Total Services: 18 (3 projects × 2 domains × 3 envs)

Dev:    6 services × 1GB   = 6GB
Stg:    6 services × 2GB   = 12GB  
Prod:   6 services × 4GB   = 24GB
───────────────────────────────────
Total:                       42GB

Buffer: 53GB - 42GB = 11GB (20% overhead) ✅ OK
```

#### Middleware Layer (Node-3)

**Services:**
```yaml
Oracle Database:
  - Version: 19c hoặc 21c
  - Memory: 16GB (SGA: 12GB, PGA: 4GB)
  - Disk: 600GB (datafiles, redo logs, archive logs)
  - Mode: Single Instance (có thể RAC sau nếu cần)
  - Backup: RMAN daily backup

Kafka:
  - Version: 3.7+
  - Memory: 8GB (JVM heap: 6GB)
  - Disk: 300GB (log segments)
  - Mode: Single broker (có thể cluster sau)
  - ZooKeeper: Embedded hoặc KRaft mode
  - Retention: 7 days

Redis:
  - Version: 7.x
  - Memory: 4GB (maxmemory)
  - Persistence: AOF + RDB
  - Mode: Standalone

NATS:
  - Version: 2.10+
  - Memory: 2GB
  - JetStream: Enabled
  - Storage: 50GB

System & Others: 2GB
───────────────────────
Total: 32GB ✅ Fit
```

**Backup Strategy:**
```bash
# Oracle: RMAN daily full + incremental
RMAN> BACKUP DATABASE PLUS ARCHIVELOG;
# Backup destination: /backup/oracle/ (rsync to Node-1)

# Kafka: Topic snapshots (nếu cần)
# Configs backup: /opt/kafka/config/

# Redis: RDB snapshots every 6h
save 21600 1

# NATS: JetStream replicas (nếu deploy trong K3s sau này)
```

---

## 🔌 Networking Design

### IP Allocation

```
Network: 192.168.1.0/24

Infrastructure:
  - Node-1: 192.168.1.10 (K3s Control)
  - Node-2: 192.168.1.11 (K3s Worker)
  - Node-3: 192.168.1.12 (Middleware)

MetalLB Pool (LoadBalancer IPs):
  - Range: 192.168.1.100 - 192.168.1.150 (51 IPs)
  - Usage:
    - nginx-ingress:     .100
    - argocd-server:     .101
    - monitoring (Grafana): .102
    - dev-dvc-backend:   .110
    - dev-dvc-dmz:       .111
    - stg-dvc-backend:   .120
    - ... (pattern based)

Cluster Internal:
  - Pod CIDR: 10.42.0.0/16
  - Service CIDR: 10.43.0.0/16
  - Cluster DNS: 10.43.0.10
```

### Ingress Strategy

**Option A: Single Nginx Ingress (RECOMMENDED)**
```yaml
# Pros: Simple, single LoadBalancer IP
# Cons: All traffic qua 1 điểm

kind: Ingress
metadata:
  name: dvc-backend-prod
spec:
  ingressClassName: nginx
  rules:
  - host: api-dvc.example.com
    http:
      paths:
      - path: /
        backend:
          service:
            name: dvc-backend-prod
            port: 8080
```

**Option B: LoadBalancer Per Service**
```yaml
# Pros: Isolated, dễ debug
# Cons: Tốn nhiều IPs

kind: Service
type: LoadBalancer
metadata:
  name: dvc-backend-prod
spec:
  ports:
  - port: 80
    targetPort: 8080
```

**Decision**: Dùng **Option A** cho dev/stg, **Option B** cho production

---

## 🔐 Security Considerations

### Network Policies
```yaml
# Isolate environments
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-cross-env
  namespace: prod-dvc-backend
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          environment: prod
```

### Secrets Management
```
Option 1: Sealed Secrets (Bitnami)
  - Encrypt secrets in Git
  - Safe for GitOps

Option 2: External Secrets Operator
  - Sync từ Vault/AWS Secrets Manager
  - Enterprise grade

Decision: Sealed Secrets (simpler, no external dependency)
```

### RBAC
```yaml
# Namespace-based access
# Dev team: full access to dev/*
# Ops team: read-only to all, write to stg/prod

ClusterRole: developer
  - namespaces: dev-*
  - verbs: [get, list, create, update, delete]

ClusterRole: operator
  - namespaces: *
  - verbs: [get, list] + [create, update, delete] for stg-*, prod-*
```

---

## 📊 Monitoring & Observability

### Stack
```yaml
Prometheus:
  - Scrape metrics từ tất cả pods
  - Retention: 15 days
  - Storage: 50GB (Longhorn PV)

Grafana:
  - Dashboards cho từng service
  - Alerts integration

Loki:
  - Centralized logging
  - Storage: 100GB

Metrics Breakdown:
  - Node metrics: node-exporter
  - K3s metrics: built-in
  - App metrics: ServiceMonitor (Prometheus Operator)
```

### Alerting Rules
```yaml
# Critical Alerts (PagerDuty)
- Node down
- Pod CrashLoopBackOff > 5 mins
- Disk usage > 85%
- Oracle Database down
- Kafka broker down

# Warning Alerts (Slack)
- High memory usage > 80%
- High CPU usage > 80% sustained 10 mins
- Kafka lag > 1000 messages
- Oracle tablespace usage > 80%
```

---

## 🚀 Deployment Workflow

### GitOps with ArgoCD

```
┌─────────────────────────────────────────────────────────┐
│                    Deployment Flow                       │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  1. Developer push code                                  │
│           ↓                                               │
│  2. Jenkins CI builds image                              │
│           ↓                                               │
│  3. Push to Harbor registry                              │
│           ↓                                               │
│  4. Update image tag in cicd-ndc/helm-chart/            │
│           ↓                                               │
│  5. Commit & push to cicd-ndc repo                       │
│           ↓                                               │
│  6. ArgoCD detects change                                │
│           ↓                                               │
│  7. ArgoCD syncs to K3s cluster                          │
│           ↓                                               │
│  8. Application deployed/updated                         │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

**Integration Points:**
- Jenkins Jenkinsfile cần update để point tới K3s cluster
- ArgoCD ApplicationSets cần tạo cho K3s cluster
- Harbor registry connectivity từ K3s nodes

---

## 🔄 Migration Plan (OpenShift → K3s)

### Phase 1: Parallel Run
```
Tuần 1-2:
  - Deploy K3s cluster
  - Deploy dev environments trên K3s
  - Test thoroughly
  - Keep OpenShift dev running

Tuần 3-4:
  - Deploy stg environments trên K3s
  - Cutover dev traffic → K3s
  - Monitor for 1 week
```

### Phase 2: Production Cutover
```
Tuần 5-6:
  - Deploy prod trên K3s
  - Blue-green deployment:
    - K3s = Green (new)
    - OpenShift = Blue (current)
  - Gradual traffic shift: 10% → 50% → 100%
  - Rollback plan: DNS switch back

Tuần 7:
  - Decommission OpenShift (nếu stable)
```

### Rollback Strategy
```yaml
# Keep OpenShift configs in legacy/ folder
# DNS TTL = 60s cho fast failover
# Database không migrate (vẫn dùng Node-3)
```

---

## 📋 Action Items

### Immediate (Week 1)
- [ ] Cấu hình 3 Nodes với static IPs
- [ ] Setup SSH keys
- [ ] Run Ansible automation (đã có sẵn)
- [ ] Verify K3s cluster hoạt động
- [ ] Deploy MetalLB + Longhorn
- [ ] Test deploy 1 sample app

### Short Term (Week 2-3)
- [ ] Setup Node-3 với PostgreSQL, Redis, NATS, RabbitMQ
- [ ] Configure ExternalName services để apps connect Node-3
- [ ] Deploy ArgoCD trên K3s
- [ ] Migrate dev environment DVC sang K3s
- [ ] Setup monitoring (Prometheus + Grafana)
- [ ] Document runbooks

### Medium Term (Week 4-6)
- [ ] Deploy all dev environments
- [ ] Deploy stg environments
- [ ] Performance testing
- [ ] Backup/restore testing
- [ ] Update Jenkins pipelines để target K3s
- [ ] Create ApplicationSets cho ArgoCD

### Long Term (Month 2+)
- [ ] Deploy production
- [ ] Migrate traffic
- [ ] Monitor & optimize
- [ ] Consider HA upgrades nếu cần
- [ ] Training cho team

---

## ❓ Open Questions

1. **DNS Management**: Dùng internal DNS hay external?
   - **Answer**: Dùng router/pfSense cho local DNS, public DNS cho external

2. **TLS Certificates**: Self-signed hay Let's Encrypt?
   - **Answer**: cert-manager + Let's Encrypt cho public, self-signed cho internal

3. **Backup Location**: Store backups ở đâu?
   - **Answer**: Node-1 mount NFS từ NAS, hoặc rsync sang remote server

4. **Disaster Recovery**: RPO/RTO targets?
   - **Answer**: RPO = 1 hour (hourly backups), RTO = 4 hours (manual restore)

5. **Cost of Scaling**: Nếu cần thêm nodes sau này?
   - **Answer**: Mua thêm Nodes hoặc migrate lên cloud (GKE, EKS)

---

**Next Steps**: Review design này với team, approve, rồi execute theo action items.

**Decision Maker**: Bạn (congminh) 😄

**Timeline**: 6-8 tuần để fully migrate từ OpenShift sang K3s.
