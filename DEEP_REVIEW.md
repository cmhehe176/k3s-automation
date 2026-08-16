# 🔍 K3s Automation - Deep Code Review

**Review Date**: 2026-08-17  
**Review Level**: HIGH (Production-ready assessment)  
**Reviewer**: Manual deep analysis

---

## 🎯 Executive Summary

**Overall Assessment**: B+ (Good, needs security & resilience improvements)

**Critical Findings**: 2  
**High Severity**: 4  
**Medium Severity**: 6  
**Low Severity**: 3

**Production Ready**: ⚠️ NO (needs fixes before production use)

---

## 🚨 CRITICAL Findings

### CRITICAL-1: No Backup Strategy

**File**: Project-wide  
**Severity**: 🔴 CRITICAL

**Issue**:
No automated backups for:
- ETCD data (K3s cluster state)
- Longhorn volumes (application data)
- Kubernetes manifests

**Risk**: 
- Catastrophic data loss on node failure
- No disaster recovery capability
- Cannot restore cluster after corruption

**Fix**: Add backup playbook

```yaml
# ansible/k3s/playbooks/10-backup.yml
---
- name: Backup K3s Cluster
  hosts: k3s_control[0]
  tasks:
    - name: Create backup directory
      file:
        path: /var/backups/k3s
        state: directory
        mode: '0700'
    
    - name: Backup ETCD snapshot
      command: k3s etcd-snapshot save
      changed_when: true
    
    - name: Find ETCD snapshots
      find:
        paths: /var/lib/rancher/k3s/server/db/snapshots
        patterns: "*.zip"
      register: snapshots
    
    - name: Copy latest snapshot to backup location
      copy:
        src: "{{ (snapshots.files | sort(attribute='mtime', reverse=true) | first).path }}"
        dest: /var/backups/k3s/
        remote_src: yes
    
    - name: Backup Longhorn volumes
      shell: |
        kubectl get pv -o json | \
        jq -r '.items[] | select(.spec.storageClassName=="longhorn") | .metadata.name' | \
        while read pv; do
          kubectl annotate pv $pv backup.longhorn.io/scheduled="true"
        done
      changed_when: true
```

**Priority**: 🔴 FIX IMMEDIATELY

---

### CRITICAL-2: Secrets in Plain Text

**File**: `ansible/k3s/playbooks/01-k3s-control.yml:13-15`  
**Severity**: 🔴 CRITICAL

**Issue**:
```yaml
- name: Save token locally
  copy:
    content: "{{ node_token.stdout }}"
    dest: /tmp/k3s-token.txt  # ⚠️ World-readable location!
```

**Risk**:
- K3s token accessible to any user on control machine
- Token allows joining nodes to cluster
- Potential unauthorized cluster access

**Fix**:
```yaml
- name: Save token securely
  copy:
    content: "{{ node_token.stdout }}"
    dest: "{{ ansible_env.HOME }}/.k3s-token"
    mode: '0600'  # Owner read-only
  no_log: true    # Don't log token value
```

**Priority**: 🔴 FIX IMMEDIATELY

---

## 🔶 HIGH Severity Findings

### HIGH-1: No Input Validation in Scripts

**File**: `ansible/k3s/scripts/teardown.sh:103-106`  
**Severity**: 🔶 HIGH

**Issue**:
```bash
# User can specify nodes
SPECIFIC_NODES+=("$2")

# Later used in commands without validation
kubectl delete node "$node"  # ⚠️ No validation!
```

**Risk**:
- Command injection via node names
- Accidental deletion of wrong nodes
- No protection against wildcards

**Fix**:
```bash
# Validate node name format
validate_node_name() {
    local node=$1
    if [[ ! "$node" =~ ^[a-z0-9]([-a-z0-9]*[a-z0-9])?$ ]]; then
        echo "❌ Invalid node name: $node"
        echo "Must be lowercase alphanumeric with hyphens"
        exit 1
    fi
}

# Use before deletion
for node in "${SPECIFIC_NODES[@]}"; do
    validate_node_name "$node"
    # Verify node exists
    if ! kubectl get node "$node" &>/dev/null; then
        echo "❌ Node not found: $node"
        exit 1
    fi
    kubectl delete node "$node"
done
```

**Priority**: 🔶 FIX BEFORE PRODUCTION

---

### HIGH-2: Hardcoded Versions

**File**: Multiple playbooks  
**Severity**: 🔶 HIGH

**Issue**:
```yaml
# ansible/k3s/playbooks/04-longhorn.yml:8
command: kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.7.1/deploy/longhorn.yaml

# ansible/argocd/playbooks/deploy.yml:10
command: kubectl apply -f https://github.com/argoproj/argo-cd/releases/download/v2.12.0/install.yaml
```

**Risk**:
- Cannot easily upgrade versions
- Manual changes required across files
- Version mismatches between environments

**Fix**: Use variables

```yaml
# ansible/inventory/group_vars/all.yml
k3s_version: "v1.30.3+k3s1"
longhorn_version: "1.7.1"
argocd_version: "2.12.0"
metallb_version: "0.14.8"

# In playbooks:
- name: Apply Longhorn manifest
  command: >
    kubectl apply -f 
    https://raw.githubusercontent.com/longhorn/longhorn/v{{ longhorn_version }}/deploy/longhorn.yaml
```

**Priority**: 🔶 FIX BEFORE PRODUCTION

---

### HIGH-3: No Network Policies

**File**: Project-wide  
**Severity**: 🔶 HIGH

**Issue**:
All pods can communicate with all pods (default Kubernetes behavior).

**Risk**:
- Compromised pod can access entire cluster
- No segmentation between namespaces
- Lateral movement in security breach

**Fix**: Add default deny policy

```yaml
# ansible/k3s/playbooks/06-network-policies.yml
---
- name: Apply Network Policies
  hosts: k3s_control[0]
  tasks:
    - name: Default deny all ingress/egress
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: networking.k8s.io/v1
          kind: NetworkPolicy
          metadata:
            name: default-deny-all
            namespace: default
          spec:
            podSelector: {}
            policyTypes:
            - Ingress
            - Egress
    
    - name: Allow DNS
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: networking.k8s.io/v1
          kind: NetworkPolicy
          metadata:
            name: allow-dns
            namespace: default
          spec:
            podSelector: {}
            policyTypes:
            - Egress
            egress:
            - to:
              - namespaceSelector:
                  matchLabels:
                    name: kube-system
              ports:
              - protocol: UDP
                port: 53
```

**Priority**: 🔶 FIX BEFORE PRODUCTION

---

### HIGH-4: No Rollback Mechanism

**File**: All deployment playbooks  
**Severity**: 🔶 HIGH

**Issue**:
Playbooks apply changes without snapshot or rollback capability.

**Risk**:
- Failed deployment leaves cluster in broken state
- Manual recovery required
- Extended downtime

**Fix**: Add pre-flight snapshots

```yaml
# Add to critical playbooks
- name: Create pre-deployment snapshot
  command: k3s etcd-snapshot save --name pre-{{ ansible_date_time.epoch }}
  changed_when: true
  
- name: Deploy changes
  # ... existing tasks
  
- name: Verify deployment
  command: kubectl get nodes
  register: verify
  failed_when: verify.rc != 0
  
- name: Rollback on failure
  block:
    - name: Find latest snapshot
      find:
        paths: /var/lib/rancher/k3s/server/db/snapshots
        patterns: "pre-*.zip"
      register: snapshots
    
    - name: Restore snapshot
      command: >
        k3s server --cluster-reset 
        --cluster-reset-restore-path={{ (snapshots.files | sort(attribute='mtime', reverse=true) | first).path }}
  when: verify.failed
```

**Priority**: 🔶 FIX BEFORE PRODUCTION

---

## 🟡 MEDIUM Severity Findings

### MEDIUM-1: Race Condition in Bootstrap

**File**: `ansible/k3s/playbooks/01-k3s-control.yml:28-32`  
**Severity**: 🟡 MEDIUM

**Issue**:
```yaml
- name: Wait for K3s to be ready
  command: kubectl get nodes
  retries: 30
  delay: 5
  # ⚠️ May pass before cluster fully initialized
```

**Risk**:
- Subsequent tasks fail intermittently
- Node not fully ready
- Certificates not generated

**Fix**:
```yaml
- name: Wait for K3s API server
  uri:
    url: https://127.0.0.1:6443/readyz
    validate_certs: no
  register: api_ready
  until: api_ready.status == 200
  retries: 60
  delay: 5

- name: Wait for node ready
  command: kubectl wait --for=condition=Ready node/{{ inventory_hostname }} --timeout=300s
  changed_when: false
```

**Priority**: 🟡 FIX SOON

---

### MEDIUM-2: No Certificate Expiry Monitoring

**File**: Project-wide  
**Severity**: 🟡 MEDIUM

**Issue**:
K3s certificates expire after 1 year. No monitoring or auto-renewal.

**Risk**:
- Sudden cluster failure when certs expire
- Manual intervention required
- Production downtime

**Fix**: Add certificate check script

```bash
# ansible/k3s/scripts/check-certs.sh
#!/bin/bash
export KUBECONFIG=~/.kube/config-k3s

echo "Checking K3s certificate expiry..."

# Get cert info
sudo openssl x509 -in /var/lib/rancher/k3s/server/tls/serving-kube-apiserver.crt -noout -enddate

# Calculate days remaining
EXPIRY=$(sudo openssl x509 -in /var/lib/rancher/k3s/server/tls/serving-kube-apiserver.crt -noout -enddate | cut -d= -f2)
EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s)
NOW_EPOCH=$(date +%s)
DAYS_LEFT=$(( ($EXPIRY_EPOCH - $NOW_EPOCH) / 86400 ))

echo "Days until expiry: $DAYS_LEFT"

if [ $DAYS_LEFT -lt 30 ]; then
    echo "⚠️ WARNING: Certificates expire in $DAYS_LEFT days!"
    echo "Renew with: systemctl restart k3s"
fi
```

**Priority**: 🟡 FIX SOON

---

### MEDIUM-3: Unprotected Kubeconfig

**File**: `ansible/k3s/playbooks/01-k3s-control.yml:36-41`  
**Severity**: 🟡 MEDIUM

**Issue**:
```yaml
- name: Fetch kubeconfig to local machine
  fetch:
    src: /etc/rancher/k3s/k3s.yaml
    dest: ~/.kube/config-k3s
    flat: yes
# ⚠️ No permission setting on local file
```

**Risk**:
- Kubeconfig readable by other users
- Cluster admin access exposed

**Fix**:
```yaml
- name: Fetch kubeconfig to local machine
  fetch:
    src: /etc/rancher/k3s/k3s.yaml
    dest: ~/.kube/config-k3s
    flat: yes
    mode: '0600'  # Set permissions

- name: Ensure kubeconfig directory permissions
  local_action:
    module: file
    path: ~/.kube
    mode: '0700'
    state: directory
```

**Priority**: 🟡 FIX SOON

---

### MEDIUM-4: No Resource Limits in Playbooks

**File**: `ansible/k3s/playbooks/04-longhorn.yml`  
**Severity**: 🟡 MEDIUM

**Issue**:
Longhorn deployed without resource limits. Can consume all node resources.

**Risk**:
- Node OOM
- Cluster instability
- Performance degradation

**Fix**: Apply resource limits

```yaml
- name: Create Longhorn resource limits
  kubernetes.core.k8s:
    state: present
    definition:
      apiVersion: v1
      kind: LimitRange
      metadata:
        name: longhorn-limits
        namespace: longhorn-system
      spec:
        limits:
        - max:
            cpu: "2"
            memory: 2Gi
          min:
            cpu: 100m
            memory: 128Mi
          type: Container
```

**Priority**: 🟡 FIX SOON

---

### MEDIUM-5: Script Path Assumptions

**File**: All scripts  
**Severity**: 🟡 MEDIUM

**Issue**:
```bash
# ansible/k3s/scripts/bootstrap.sh:12
if [ ! -f "ansible.cfg" ]; then
    echo "❌ Error: Run from ansible/ directory"
    exit 1
fi
```

**Risk**:
- Scripts fail if ansible.cfg missing
- No validation of correct ansible/ directory
- Could run in wrong project

**Fix**:
```bash
# More robust check
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [ ! -f "$ANSIBLE_ROOT/ansible.cfg" ] || \
   [ ! -d "$ANSIBLE_ROOT/k3s" ]; then
    echo "❌ Error: Not in K3s automation ansible directory"
    echo "Expected: <project>/ansible/"
    exit 1
fi

cd "$ANSIBLE_ROOT"
```

**Priority**: 🟡 FIX SOON

---

### MEDIUM-6: No Health Checks After Deployment

**File**: All deployment playbooks  
**Severity**: 🟡 MEDIUM

**Issue**:
Playbooks complete without verifying service health.

**Risk**:
- Silent failures
- Broken deployment marked successful
- Manual troubleshooting required

**Fix**: Add health checks

```yaml
# Add to end of each deployment playbook
- name: Health check - All pods running
  shell: |
    kubectl get pods -n {{ namespace }} -o json | \
    jq -e '.items | all(.status.phase == "Running")'
  register: health
  retries: 10
  delay: 30
  until: health.rc == 0
  changed_when: false

- name: Display unhealthy pods
  command: kubectl get pods -n {{ namespace }} --field-selector=status.phase!=Running
  when: health.failed
```

**Priority**: 🟡 FIX SOON

---

## 🟢 LOW Severity Findings

### LOW-1: Missing Shell Options

**File**: Multiple scripts  
**Severity**: 🟢 LOW

**Issue**:
```bash
#!/bin/bash
set -e
# ⚠️ Missing: set -u (undefined variable), set -o pipefail
```

**Risk**:
- Silent failures in pipelines
- Undefined variable bugs

**Fix**:
```bash
#!/bin/bash
set -euo pipefail  # Exit on error, undefined var, pipe failure
IFS=$'\n\t'        # Safer word splitting
```

**Priority**: 🟢 IMPROVE

---

### LOW-2: Verbose Output

**File**: All playbooks  
**Severity**: 🟢 LOW

**Issue**:
Tasks output sensitive information (IPs, configs) to stdout.

**Fix**:
```yaml
- name: Sensitive task
  command: some-command
  no_log: true  # Suppress output
```

**Priority**: 🟢 IMPROVE

---

### LOW-3: No Ansible Lint

**File**: Project-wide  
**Severity**: 🟢 LOW

**Issue**:
No ansible-lint in development workflow.

**Fix**:
```yaml
# .github/workflows/lint.yml
name: Lint
on: [push]
jobs:
  ansible-lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: pip install ansible-lint
      - run: ansible-lint ansible/**/*.yml
```

**Priority**: 🟢 IMPROVE

---

## 📊 Summary by Category

### Security (7 findings)
- 🔴 CRITICAL: 2
- 🔶 HIGH: 2
- 🟡 MEDIUM: 3

### Reliability (5 findings)
- 🔶 HIGH: 2
- 🟡 MEDIUM: 3

### Code Quality (4 findings)
- 🟡 MEDIUM: 1
- 🟢 LOW: 3

---

## 🎯 Priority Action Plan

### Week 1 (CRITICAL)
1. ✅ Add backup automation (CRITICAL-1)
2. ✅ Fix token security (CRITICAL-2)
3. ✅ Add input validation (HIGH-1)

### Week 2 (HIGH)
4. ✅ Implement network policies (HIGH-3)
5. ✅ Add rollback mechanism (HIGH-4)
6. ✅ Centralize versions (HIGH-2)

### Week 3 (MEDIUM)
7. Fix race conditions (MEDIUM-1)
8. Add cert monitoring (MEDIUM-2)
9. Protect kubeconfig (MEDIUM-3)
10. Add resource limits (MEDIUM-4)

### Week 4 (POLISH)
11. Improve script robustness (MEDIUM-5)
12. Add health checks (MEDIUM-6)
13. Apply LOW fixes

---

## 🏆 What's Already Good

**Strengths**:
1. ✅ Good project structure
2. ✅ Clear documentation
3. ✅ Fixed Longhorn conflict proactively
4. ✅ Used `git mv` to preserve history
5. ✅ Error messages with emoji (good UX)
6. ✅ Confirmation prompts on teardown
7. ✅ Pre-flight connectivity checks

---

## 📈 Production Readiness Score

**Current**: 65/100

**After CRITICAL fixes**: 75/100  
**After HIGH fixes**: 85/100  
**After MEDIUM fixes**: 95/100  

**Target for Production**: 90+/100

---

**Next Review**: After implementing CRITICAL and HIGH fixes
