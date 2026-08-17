# Implementation Plan: OKD Deployment on Bare-Metal

## 🎯 Objective

Deploy OKD (OpenShift Origin) cluster on bare-metal servers using Ansible, following the same structure as K3s automation.

---

## 📊 Current Context

**Existing Structure:**
```
ansible/
├── k3s/          # K3s cluster (working)
├── argocd/       # ArgoCD GitOps
└── inventory/    # Shared inventory
```

**New Structure:**
```
ansible/
├── k3s/          # K3s cluster
├── argocd/       # ArgoCD GitOps
├── okd/          # OKD cluster (NEW)
│   ├── playbooks/
│   ├── roles/
│   └── scripts/
└── inventory/    # Shared inventory
```

---

## 🏗️ OKD Architecture

### Deployment Methods

**Option A: OKD 4.x (IPI - Installer Provisioned Infrastructure)**
- ❌ Requires specific infrastructure (AWS, vSphere, etc.)
- ❌ Not suitable for arbitrary bare-metal

**Option B: OKD 4.x (UPI - User Provisioned Infrastructure)** ⭐ **RECOMMENDED**
- ✅ Full control over infrastructure
- ✅ Works on any bare-metal
- ✅ Production-grade
- ⚠️ Complex setup (multiple nodes, load balancers, DNS)

**Option C: Single Node OpenShift (SNO)**
- ✅ Simplest for testing
- ✅ One node = control + worker
- ❌ Not for production
- ✅ Good starting point

---

## 📋 Requirements Analysis

### Minimum Node Requirements (UPI)

**Bootstrap Node** (temporary):
- 4 vCPUs, 16GB RAM, 120GB disk
- Used only during installation

**Control Plane Nodes** (3 nodes for HA):
- 4 vCPUs, 16GB RAM, 120GB disk per node
- node-1, node-2, node-3

**Worker Nodes** (2+ nodes):
- 2 vCPUs, 8GB RAM, 120GB disk per node
- node-4, node-5, ...

**Infrastructure Node** (1 node):
- Load Balancer (HAProxy)
- DNS server (dnsmasq or bind)
- Web server (httpd for ignition configs)
- Can be the Ansible control machine

### Network Requirements

- Static IPs for all nodes
- DNS entries for:
  - `api.<cluster-name>.<domain>` → Load balancer
  - `api-int.<cluster-name>.<domain>` → Load balancer
  - `*.apps.<cluster-name>.<domain>` → Load balancer (wildcard)
  - Each node: `<node-name>.<cluster-name>.<domain>`
- Load balancer ports:
  - 6443 (Kubernetes API)
  - 22623 (Machine Config Server)
  - 80/443 (Ingress HTTP/HTTPS)

---

## 🎨 Implementation Approach

### Phase 1: Infrastructure Preparation

**Goal**: Setup DNS, Load Balancer, Web Server

**Tasks**:
1. Create `ansible/okd/` structure
2. Setup infrastructure node (DNS + HAProxy + httpd)
3. Prepare inventory for OKD nodes

**Playbooks**:
- `00-prerequisites.yml` - Install required packages
- `01-infrastructure.yml` - Setup DNS, LB, httpd

**Roles**:
- `okd-infrastructure/` - Configure DNS/HAProxy/httpd

**Why**: OKD requires proper DNS resolution and load balancing before installation.

### Phase 2: Generate Ignition Configs

**Goal**: Create OpenShift installation manifests and ignition configs

**Tasks**:
1. Download `openshift-install` binary
2. Create `install-config.yaml`
3. Generate Kubernetes manifests
4. Generate ignition configs (bootstrap, master, worker)
5. Host ignition files on web server

**Playbooks**:
- `02-generate-configs.yml` - Create ignition configs

**Roles**:
- `okd-ignition/` - Generate and host configs

**Why**: Ignition configs are CoreOS's first-boot configuration system.

### Phase 3: Bootstrap Cluster

**Goal**: Start bootstrap process and initial control plane

**Tasks**:
1. Boot bootstrap node with ignition
2. Boot control plane nodes with ignition
3. Wait for bootstrap to complete
4. Approve pending CSRs

**Playbooks**:
- `03-bootstrap.yml` - Start bootstrap node
- `04-control-plane.yml` - Start control nodes

**Roles**:
- `okd-bootstrap/` - Bootstrap node setup
- `okd-control-plane/` - Control plane setup

**How to apply**: This is the most critical phase. Nodes need to PXE boot or use ISO with embedded ignition.

### Phase 4: Worker Nodes

**Goal**: Add worker nodes to cluster

**Tasks**:
1. Boot worker nodes with ignition
2. Approve worker CSRs
3. Verify nodes are Ready

**Playbooks**:
- `05-workers.yml` - Add worker nodes

**Roles**:
- `okd-workers/` - Worker node setup

### Phase 5: Post-Installation

**Goal**: Configure cluster for use

**Tasks**:
1. Remove bootstrap node
2. Configure image registry storage
3. Configure ingress
4. Create admin user
5. Install operators (optional)

**Playbooks**:
- `06-post-install.yml` - Post-install tasks
- `07-storage.yml` - Configure storage
- `08-ingress.yml` - Configure ingress

**Roles**:
- `okd-post-install/` - Post-installation config

### Phase 6: Management Scripts

**Goal**: Create easy-to-use management scripts

**Scripts**:
```bash
okd/scripts/
├── prepare-infrastructure.sh  # Setup DNS/LB/httpd
├── generate-configs.sh        # Create ignition configs
├── bootstrap-cluster.sh       # Start bootstrap process
├── add-workers.sh            # Add worker nodes
├── teardown.sh               # Cleanup cluster
└── README.md                 # Documentation
```

---

## 🔧 Alternative: Single Node OpenShift (SNO)

**Simpler approach for testing:**

### Requirements
- 1 node: 8 vCPUs, 32GB RAM, 120GB disk
- No separate load balancer needed
- Simpler DNS (just node hostname)

### Structure
```
ansible/okd/
├── playbooks/
│   ├── 00-prerequisites.yml
│   ├── 01-sno-install.yml
│   └── 99-teardown.yml
├── roles/
│   └── okd-sno/
└── scripts/
    ├── install-sno.sh
    └── teardown.sh
```

### Benefits
- Much simpler setup
- Good for development/testing
- Can upgrade to multi-node later

**Recommendation**: Start with SNO, then expand to multi-node if needed.

---

## 📝 Detailed Task Breakdown

### Task 1: Create Directory Structure

```bash
mkdir -p ansible/okd/{playbooks,roles,scripts}
mkdir -p ansible/okd/roles/{okd-infrastructure,okd-ignition,okd-bootstrap,okd-control-plane,okd-workers,okd-post-install}
```

### Task 2: Update ansible.cfg

```ini
[defaults]
roles_path = k3s/roles:argocd/roles:okd/roles
```

### Task 3: Create Infrastructure Playbook

**File**: `ansible/okd/playbooks/01-infrastructure.yml`

**What it does**:
- Install dnsmasq for DNS
- Install HAProxy for load balancing
- Install httpd for hosting ignition configs
- Configure firewall rules

### Task 4: Create Ignition Generation Playbook

**File**: `ansible/okd/playbooks/02-generate-configs.yml`

**What it does**:
- Download openshift-install binary
- Create install-config.yaml from template
- Generate manifests
- Generate ignition configs
- Copy ignition configs to httpd

### Task 5: Create Bootstrap Scripts

**File**: `ansible/okd/scripts/bootstrap-cluster.sh`

**What it does**:
1. Run infrastructure playbook
2. Generate ignition configs
3. Display instructions for booting nodes
4. Monitor bootstrap progress
5. Approve CSRs automatically

---

## 🧪 Verification Steps

After each phase:

**Phase 1 (Infrastructure)**:
```bash
# DNS check
dig api.okd.example.com
dig node-1.okd.example.com

# HAProxy check
curl http://<infrastructure-node>:9000/stats

# Ignition files check
curl http://<infrastructure-node>:8080/bootstrap.ign
```

**Phase 3 (Bootstrap)**:
```bash
# Bootstrap progress
openshift-install wait-for bootstrap-complete --log-level=debug

# Check nodes
export KUBECONFIG=~/okd/auth/kubeconfig
oc get nodes
```

**Phase 5 (Post-Install)**:
```bash
# Cluster operators
oc get clusteroperators

# Console URL
oc whoami --show-console
```

---

## ⚠️ Challenges & Solutions

| Challenge | Solution |
|-----------|----------|
| Complex DNS setup | Use dnsmasq with simple config, or external DNS |
| Load balancer required | HAProxy on infrastructure node |
| CoreOS-based (no SSH initially) | Use ignition configs for first-boot setup |
| CSR approval | Automate with `oc adm certificate approve` script |
| Large downloads (~500MB installer) | Cache locally on infrastructure node |
| Bootstrap failure | Check logs: `journalctl -b -f -u bootkube.service` |

---

## 📊 Comparison: K3s vs OKD Setup

| Aspect | K3s | OKD |
|--------|-----|-----|
| **Nodes** | 1+ | 4+ (1 infra, 3 control, 1+ worker) |
| **Setup Time** | 5-10 minutes | 1-2 hours |
| **Complexity** | Low | High |
| **DNS Required** | No | Yes (critical) |
| **Load Balancer** | No | Yes (critical) |
| **Binary Size** | ~60MB | ~500MB |
| **Features** | Basic K8s | Full OpenShift (Routes, Projects, etc.) |

---

## 🎯 Success Criteria

- [ ] Infrastructure node configured (DNS, HAProxy, httpd)
- [ ] Ignition configs generated and hosted
- [ ] Bootstrap node started successfully
- [ ] Control plane nodes joined and Ready
- [ ] Worker nodes joined and Ready
- [ ] All cluster operators Available
- [ ] Console accessible via browser
- [ ] Sample app deployed successfully
- [ ] Scripts working from `ansible/` directory
- [ ] Documentation complete in `okd/scripts/README.md`

---

## 💡 Recommendations

### For Testing/Development
**→ Start with Single Node OpenShift (SNO)**
- Simpler setup
- Lower resource requirements
- Good for learning OKD

### For Production
**→ Use UPI Multi-Node**
- 3 control plane nodes (HA)
- 2+ worker nodes
- Separate infrastructure node
- Proper DNS and load balancing

### Hybrid Approach
**→ Keep K3s + Add OKD**
- K3s for lightweight workloads
- OKD for enterprise features
- Share same inventory
- Use different node groups

---

## 📚 Documentation Structure

```
ansible/okd/scripts/README.md
- Prerequisites
- Architecture diagram
- Step-by-step installation
- Troubleshooting
- Common issues
```

---

## 🔮 Future Enhancements

1. **Automated CSR approval** - Script to auto-approve node certificates
2. **Storage integration** - Longhorn or OCS for persistent storage
3. **Monitoring** - Prometheus/Grafana operators
4. **Backup/Restore** - ETCD backup scripts
5. **Upgrade automation** - OKD version upgrade playbooks

---

## 📌 Next Steps

1. **Choose deployment method**: SNO or multi-node?
2. **Verify requirements**: Do you have enough nodes/resources?
3. **Start with Phase 1**: Create directory structure
4. **Create infrastructure playbook**: DNS + HAProxy + httpd
5. **Test incrementally**: Don't skip verification steps

---

**Estimated Implementation Time**:
- SNO: 4-6 hours (first time)
- Multi-node UPI: 8-12 hours (first time)

**Question for you**: 
- How many nodes do you have available?
- Do you want SNO (simple) or multi-node (production)?
- Do you have existing DNS infrastructure or need dnsmasq?
