# 📋 K3s Cluster - System Requirements & Prerequisites

**Project**: K3s Cluster cho NDC Microservices  
**Date**: 2026-08-16  
**Version**: 1.0

---

## 🎯 Business Requirements

### Applications to Host
- **3 microservice projects**: DVC, PAKN, Thanh Toán
- **2 domains per project**: 
  - `backend` (Core services)
  - `dmz` (Frontend/Public-facing)
- **3 environments**: dev, stg, prod
- **Total deployments**: 18 services (3 projects × 2 domains × 3 envs)

### Middleware Stack
- **Oracle Database 19c/21c** (Node-3)
- **Apache Kafka 3.7+** (Node-3)
- **Redis 7.x** (Node-3 hoặc trong K3s)
- **NATS 2.10+** (Node-3 hoặc trong K3s)

### SLA Requirements
- **Availability**: 99.5% uptime (dev/stg), 99.9% (prod)
- **RTO** (Recovery Time Objective): 4 hours
- **RPO** (Recovery Point Objective): 1 hour
- **Scalability**: Có thể add thêm nodes sau

---

## 💻 Hardware Requirements

### Minimum Hardware (As-Is)

**Node-1 (Control Plane + Worker)**
```yaml
Role: K3s Server + Worker
CPU: 32 cores (recommended)
RAM: 32GB
Disk: 1TB SSD/NVMe
Network: 1Gbps Ethernet
IP: 192.168.1.10 (static)
OS: Ubuntu 22.04 LTS hoặc RHEL 8+
```

**Node-2 (Worker)**
```yaml
Role: K3s Worker
CPU: 32 cores
RAM: 32GB
Disk: 1TB SSD/NVMe
Network: 1Gbps Ethernet
IP: 192.168.1.11 (static)
OS: Ubuntu 22.04 LTS hoặc RHEL 8+
```

**Node-3 (Middleware - Bare Metal)**
```yaml
Role: Database & Message Queue Layer
CPU: 32 cores
RAM: 32GB
Disk: 1TB SSD (RAID1 recommended cho Oracle)
Network: 1Gbps Ethernet
IP: 192.168.1.12 (static)
OS: Ubuntu 22.04 LTS (cho Kafka) hoặc Oracle Linux 8 (cho Oracle DB)
```

### Resource Allocation

**K3s Cluster (Node-1 + Node-2):**
```
Total Resources:
  CPU: 64 cores
  RAM: 64GB
  Storage: 2TB (distributed via Longhorn)

Reserved for System:
  CPU: 4 cores
  RAM: 8GB

Available for Applications:
  CPU: 60 cores
  RAM: 56GB

Per-Service Allocation (estimated):
  Dev:  512Mi RAM, 100m CPU
  Stg:  1Gi RAM, 250m CPU
  Prod: 2-4Gi RAM, 500m-1 CPU
```

**Node-3 Middleware:**
```
Oracle Database: 16GB RAM, 600GB disk
Kafka:           8GB RAM, 300GB disk
Redis:           4GB RAM, 50GB disk
NATS:            2GB RAM, 50GB disk
System:          2GB RAM
```

---

## 🌐 Network Requirements

### Network Topology
```
Internet
   |
   +--> Router/Firewall (192.168.1.1)
          |
          +--> Node-1: 192.168.1.10 (Control Plane)
          |
          +--> Node-2: 192.168.1.11 (Worker)
          |
          +--> Node-3: 192.168.1.12 (Middleware)
          |
          +--> MetalLB Pool: 192.168.1.100-150
```

### Required Ports

**Node-1 (Control Plane):**
| Port | Protocol | Purpose | Allow From |
|------|----------|---------|------------|
| 6443 | TCP | Kubernetes API | Node-2, Node-3, Admin laptop |
| 10250 | TCP | Kubelet | Node-1, Node-2 |
| 2379-2380 | TCP | etcd | Node-1 (internal) |
| 22 | TCP | SSH | Admin laptop |

**Node-2 (Worker):**
| Port | Protocol | Purpose | Allow From |
|------|----------|---------|------------|
| 10250 | TCP | Kubelet | Node-1 |
| 22 | TCP | SSH | Admin laptop |

**Node-3 (Middleware):**
| Port | Protocol | Purpose | Allow From |
|------|----------|---------|------------|
| 1521 | TCP | Oracle DB | Node-1, Node-2 (pods) |
| 9092 | TCP | Kafka | Node-1, Node-2 (pods) |
| 6379 | TCP | Redis | Node-1, Node-2 (pods) |
| 4222 | TCP | NATS | Node-1, Node-2 (pods) |
| 22 | TCP | SSH | Admin laptop |

**LoadBalancer (MetalLB):**
| Port | Protocol | Purpose | Allow From |
|------|----------|---------|------------|
| 80 | TCP | HTTP Ingress | Internet/Internal |
| 443 | TCP | HTTPS Ingress | Internet/Internal |

### Bandwidth
- **Internal**: 1Gbps minimum giữa Node-1, Node-2, Node-3
- **External**: 100Mbps minimum cho user traffic
- **Latency**: < 1ms giữa nodes (same LAN)

### DNS
- **Internal DNS**: Có thể dùng `/etc/hosts` hoặc local DNS server
- **External DNS**: Cần cho public services (optional)

**Example `/etc/hosts`:**
```
192.168.1.10  node-1 k3s-control
192.168.1.11  node-2 k3s-worker-1
192.168.1.12  node-3 middleware
```

---

## 🔧 Software Requirements

### Control Machine (Laptop/Workstation)
```yaml
OS: Linux/macOS/WSL2
Tools:
  - Ansible >= 2.14
  - kubectl >= 1.28
  - SSH client
  - Git
Python: >= 3.8
Ansible Collections:
  - kubernetes.core
```

**Installation:**
```bash
# Ubuntu/Debian
sudo apt install ansible python3-pip git

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install kubectl /usr/local/bin/

# Install Ansible collection
ansible-galaxy collection install kubernetes.core
```

### Target Nodes (Node-1, Node-2, Node-3)

**Operating System:**
- **Recommended**: Ubuntu 22.04 LTS Server
- **Alternative**: RHEL 8+, Rocky Linux 8+, Debian 11+
- **Architecture**: x86_64 (amd64)

**Required Packages** (auto-installed by Ansible):
```yaml
Base:
  - curl, wget, git
  - net-tools, htop
  - vim (optional)

For K3s:
  - open-iscsi (for Longhorn storage)
  - nfs-common (for NFS storage)

For Oracle (Node-3):
  - oracle-database-preinstall-19c
  - libaio, ksh

For Kafka (Node-3):
  - openjdk-11-jdk
```

**Kernel Requirements:**
```yaml
Kernel version: >= 5.4
Modules:
  - overlay
  - br_netfilter
  - ip_vs
  - ip_vs_rr
  - nf_conntrack

Sysctl:
  net.bridge.bridge-nf-call-iptables: 1
  net.bridge.bridge-nf-call-ip6tables: 1
  net.ipv4.ip_forward: 1
```

---

## 🔐 Security Requirements

### SSH Access
- **Method**: SSH key-based authentication (password auth disabled)
- **User**: Non-root user với sudo privileges
- **Key type**: RSA 4096-bit hoặc Ed25519

**Setup:**
```bash
# Generate key
ssh-keygen -t ed25519 -C "k3s-automation"

# Copy to nodes
ssh-copy-id admin@192.168.1.10
ssh-copy-id admin@192.168.1.11
ssh-copy-id admin@192.168.1.12
```

### Firewall
- **Recommended**: `ufw` (Ubuntu) hoặc `firewalld` (RHEL)
- **Default policy**: Deny all, allow specific ports
- **Internal traffic**: Allow 192.168.1.0/24

### Secrets Management
- **K3s token**: Dùng environment variable hoặc Ansible Vault
- **Database passwords**: Ansible Vault hoặc Sealed Secrets
- **Kubeconfig**: Permissions 0600, không share

---

## 📦 Storage Requirements

### K3s Cluster Storage (Longhorn)
```yaml
Type: Distributed block storage
Replication: 2 (data replicated across Node-1 và Node-2)
Minimum free space per node: 100GB
Recommended: 500GB per node

Storage Classes:
  - longhorn (default, replicated)
  - local-path (K3s built-in, single node)
```

### Node-3 Storage (Middleware)
```yaml
Oracle Database:
  - /opt/oracle: 50GB (binaries)
  - /u01/oradata: 500GB (data files)
  - /u01/archive: 50GB (archive logs)

Kafka:
  - /var/lib/kafka: 300GB (log segments)

Redis:
  - /var/lib/redis: 50GB (RDB/AOF files)

NATS:
  - /var/lib/nats: 50GB (JetStream)
```

### Backup Storage
```yaml
Location: External NAS hoặc remote server
Method: rsync, RMAN (Oracle), Velero (K8s)
Retention:
  - Daily: 7 days
  - Weekly: 4 weeks
  - Monthly: 12 months
Size: ~500GB cho full backups
```

---

## 🕐 Time & Timezone

**All nodes phải sync time:**
```yaml
Timezone: Asia/Ho_Chi_Minh (UTC+7)
NTP: Enabled với chrony hoặc systemd-timesyncd
Time sync tolerance: < 5 seconds drift
```

**Setup:**
```bash
# Set timezone
sudo timedatectl set-timezone Asia/Ho_Chi_Minh

# Enable NTP
sudo timedatectl set-ntp true

# Verify
timedatectl status
```

---

## 📊 Monitoring & Logging

### Requirements
```yaml
Monitoring:
  - Prometheus (metrics)
  - Grafana (dashboards)
  - Alertmanager (alerts)
  Storage: 50GB retention 15 days

Logging:
  - Loki (log aggregation)
  - Storage: 100GB retention 30 days

Alerting:
  - Critical: PagerDuty/Email
  - Warning: Slack/Teams
```

---

## 🚀 Deployment Prerequisites Checklist

**Before Running Ansible:**

### Network Setup
- [ ] All 3 Nodes có static IPs (192.168.1.10-12)
- [ ] Connectivity giữa Node-1, Node-2, Node-3 OK
- [ ] Router cho phép traffic giữa nodes
- [ ] DNS resolution hoạt động (hoặc `/etc/hosts` configured)
- [ ] Internet access từ tất cả nodes (để download K3s, images)

### Control Machine
- [ ] Ansible >= 2.14 installed
- [ ] kubectl installed
- [ ] SSH keys generated
- [ ] SSH keys copied lên tất cả nodes
- [ ] `ansible all -m ping` thành công

### Target Nodes (Node-1, Node-2)
- [ ] Ubuntu 22.04 LTS installed
- [ ] User account với sudo privileges created
- [ ] SSH key-based auth working
- [ ] Password auth disabled (recommended)
- [ ] Swap disabled (`swapon -s` returns nothing)
- [ ] Hostname set correctly
- [ ] Disk có ít nhất 100GB free space

### Middleware Node (Node-3)
- [ ] OS installed (Ubuntu/Oracle Linux)
- [ ] User account với sudo privileges
- [ ] SSH key-based auth working
- [ ] Disk partitions prepared:
  - [ ] /opt/oracle (50GB)
  - [ ] /u01 (600GB cho Oracle)
  - [ ] /var/lib/kafka (300GB)
- [ ] Oracle Database installer downloaded (nếu dùng Oracle)

### Configuration Files
- [ ] `ansible/inventory/hosts.ini` updated với IPs đúng
- [ ] `ansible/inventory/group_vars/all.yml` reviewed
- [ ] `K3S_TOKEN` environment variable set (hoặc dùng Ansible Vault)
- [ ] `metallb_ip_range` không conflict với DHCP

---

## 📞 Support & Escalation

### Roles & Responsibilities

**DevOps Lead**: Congminh
- Overall architecture
- Ansible automation
- K3s cluster management

**Database Admin** (TBD):
- Oracle Database setup (Node-3)
- Backup & restore
- Performance tuning

**Network Admin** (TBD):
- Firewall rules
- Load balancer config
- DNS management

**Developer Team**:
- Application deployment
- ArgoCD ApplicationSets
- Debugging application issues

### Escalation Path
```
Level 1: Self-service (README, docs)
   ↓
Level 2: DevOps team (Slack/Teams)
   ↓
Level 3: Infrastructure team
   ↓
Level 4: Vendor support (K3s, Oracle)
```

---

## 📚 Documentation Locations

```
k3s-automation/
├── README.md              # Main guide
├── QUICKSTART.md          # 5-minute setup
├── docs/
│   ├── ARCHITECTURE.md    # (TODO) Architecture details
│   ├── BRAINSTORM.md      # Design decisions
│   ├── CODE_REVIEW.md     # Review findings
│   ├── SECURITY.md        # Security best practices
│   └── REQUIREMENTS.md    # This file
```

---

## ✅ Success Criteria

**Phase 1 (Node-1 Bootstrap) - DONE:**
- [ ] Node-1 K3s cluster running
- [ ] `kubectl get nodes` shows 1 node Ready
- [ ] Longhorn storage class available
- [ ] MetalLB LoadBalancer working
- [ ] Test deployment successful

**Phase 2 (Add Node-2) - DONE:**
- [ ] Node-2 joined cluster
- [ ] `kubectl get nodes` shows 2 nodes Ready
- [ ] Pods distributed across both nodes
- [ ] Storage replication working (2 replicas)

**Phase 3 (Add Node-3 Middleware) - TODO:**
- [ ] Oracle Database installed và running
- [ ] Kafka cluster running
- [ ] Redis accessible từ K3s pods
- [ ] NATS accessible từ K3s pods
- [ ] ExternalName services created trong K3s

**Phase 4 (Application Deployment) - TODO:**
- [ ] ArgoCD installed
- [ ] ApplicationSets created
- [ ] Dev environment deployed
- [ ] Stg environment deployed
- [ ] Prod environment deployed
- [ ] CI/CD pipeline working

---

**Created**: 2026-08-16  
**Owner**: Congminh  
**Status**: Ready for Deployment
