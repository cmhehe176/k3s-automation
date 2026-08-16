# 🔍 K3s Automation Code Review Report

**Date**: 2026-08-16  
**Reviewer**: AI Code Review  
**Scope**: Ansible automation trong `k3s-automation/`

---

## 📊 Summary

| Category | Status | Count |
|----------|--------|-------|
| 🔴 Critical | FIXED | 1 |
| 🟡 High | Needs Review | 3 |
| 🟢 Medium | Advisory | 5 |
| ℹ️ Low | Optional | 4 |

**Overall Grade**: B+ (Good, production-ready sau khi fix High issues)

---

## 🔴 Critical Issues (FIXED)

### 1. Hardcoded K3s Token ✅ FIXED
**File**: `ansible/inventory/group_vars/all.yml:6`

**Issue**: Token hardcoded, có thể leak vào Git.

**Fixed**: Giờ token auto-generate hoặc đọc từ env var `K3S_TOKEN`.

```yaml
# Before (INSECURE):
k3s_token: "my-super-secret-k3s-token-change-me"

# After (SECURE):
k3s_token: "{{ lookup('env', 'K3S_TOKEN') | default('CHANGE-ME-' + lookup('password', '/dev/null chars=ascii_letters,digits length=32'), true) }}"
```

---

## 🟡 High Priority Issues

### 2. Token File Permissions
**File**: `ansible/roles/k3s-server/tasks/main.yml:63`

**Issue**: Token lưu vào `/tmp/k3s-node-token` không set permissions.

```yaml
# Current:
- name: Save token locally
  copy:
    content: "{{ node_token.content | b64decode }}"
    dest: /tmp/k3s-node-token
  delegate_to: localhost
  become: no
```

**Recommendation**:
```yaml
- name: Save token locally
  copy:
    content: "{{ node_token.content | b64decode }}"
    dest: /tmp/k3s-node-token
    mode: '0600'  # <-- ADD THIS
  delegate_to: localhost
  become: no
```

---

### 3. Kubeconfig Permissions
**File**: `ansible/roles/k3s-server/tasks/main.yml:37-40`

**Issue**: Kubeconfig được set `mode: '0644'` (readable by all users).

```yaml
# Current (INSECURE):
- name: Set kubeconfig permissions
  file:
    path: /etc/rancher/k3s/k3s.yaml
    mode: '0644'
```

**Risk**: Bất kỳ user nào trên Node-1 đều có thể đọc kubeconfig và control cluster!

**Recommendation**:
```yaml
- name: Set kubeconfig permissions
  file:
    path: /etc/rancher/k3s/k3s.yaml
    mode: '0600'  # Only root can read
    owner: root
    group: root
```

**Impact**: Nếu cần non-root user access, tạo riêng ServiceAccount cho họ thay vì share kubeconfig.

---

### 4. No Error Handling for Network Failures
**File**: `ansible/roles/k3s-agent/tasks/main.yml:7-9`

**Issue**: Nếu `/tmp/k3s-node-token` không tồn tại, task sẽ fail không rõ ràng.

```yaml
# Current:
- name: Read K3s token from local file
  set_fact:
    k3s_node_token: "{{ lookup('file', '/tmp/k3s-node-token') }}"
```

**Recommendation**:
```yaml
- name: Check if K3s token exists
  stat:
    path: /tmp/k3s-node-token
  delegate_to: localhost
  register: token_file
  become: no

- name: Fail if token not found
  fail:
    msg: "K3s token not found! Run bootstrap.sh first to create control plane."
  when: not token_file.stat.exists

- name: Read K3s token from local file
  set_fact:
    k3s_node_token: "{{ lookup('file', '/tmp/k3s-node-token') }}"
```

---

## 🟢 Medium Priority Issues

### 5. No Idempotency Check for K3s Installation
**File**: `ansible/roles/k3s-server/tasks/main.yml:14-23`

**Issue**: Shell command có `creates: /usr/local/bin/k3s` nhưng nếu K3s đã cài với version khác, sẽ không upgrade.

**Recommendation**: Thêm check version:
```yaml
- name: Check installed K3s version
  command: /usr/local/bin/k3s --version
  register: installed_version
  failed_when: false
  changed_when: false

- name: Install or upgrade K3s server
  shell: |
    INSTALL_K3S_VERSION="{{ k3s_version }}" \
    K3S_TOKEN="{{ k3s_token }}" \
    sh /tmp/k3s-install.sh server \
    {{ k3s_server_args | join(' ') }}
  when: >
    not k3s_binary.stat.exists or
    k3s_version not in installed_version.stdout
```

---

### 6. No Validation for MetalLB IP Range
**File**: `ansible/inventory/group_vars/all.yml:17`

**Issue**: IP range `192.168.1.100-192.168.1.150` có thể conflict với DHCP.

**Recommendation**: Thêm validation task:
```yaml
- name: Validate MetalLB IP range
  assert:
    that:
      - metallb_ip_range is defined
      - metallb_ip_range | regex_search('^\d+\.\d+\.\d+\.\d+-\d+\.\d+\.\d+\.\d+$')
    fail_msg: "Invalid MetalLB IP range format"
```

---

### 7. Missing Health Check After Installation
**File**: `ansible/playbooks/01-k3s-control.yml`

**Issue**: Playbook chỉ check port 6443, không verify cluster actually healthy.

**Recommendation**:
```yaml
- name: Wait for all system pods to be ready
  command: kubectl wait --for=condition=ready pod --all -n kube-system --timeout=300s
  register: pods_ready
  retries: 3
  delay: 10
  until: pods_ready.rc == 0
```

---

### 8. No Cleanup of Temporary Files
**Files**: `bootstrap.sh`, `add-node.sh`

**Issue**: Scripts không cleanup `/tmp/k3s-node-token` sau khi done.

**Recommendation**:
```bash
# Thêm trap để cleanup on exit
trap 'rm -f /tmp/k3s-node-token' EXIT
```

---

### 9. Longhorn Deployment Without Prerequisites Check
**File**: `ansible/playbooks/04-longhorn.yml:7-12`

**Issue**: Longhorn cần `open-iscsi` package, đã cài trong common role nhưng không verify.

**Recommendation**:
```yaml
- name: Verify iscsid service is running
  systemd:
    name: iscsid
    state: started
  delegate_to: "{{ item }}"
  loop: "{{ groups['k3s_cluster'] }}"
```

---

## ℹ️ Low Priority / Advisory

### 10. Hardcoded Versions
**Files**: Multiple

**Issue**: Longhorn, MetalLB versions hardcoded trong playbooks.

**Recommendation**: Move vào `group_vars/all.yml`:
```yaml
longhorn_version: v1.7.1
metallb_version: v0.14.8
```

---

### 11. No Logging Configuration
**Issue**: Ansible output không log vào file.

**Recommendation**: Thêm vào `ansible.cfg`:
```ini
[defaults]
log_path = /var/log/ansible-k3s.log
```

---

### 12. Missing Rollback Strategy
**Issue**: Nếu deployment fail giữa chừng, không có automated rollback.

**Recommendation**: Document manual rollback steps trong README.

---

### 13. No Monitoring for Deployment Status
**Issue**: Scripts không integrate với monitoring/alerting.

**Recommendation**: Thêm webhook notifications:
```bash
# Thêm vào cuối mỗi script
curl -X POST https://slack.webhook.url \
  -d '{"text":"K3s deployment completed on Node-1"}'
```

---

## ✅ What's Good

1. **✅ Idempotency**: Roles có check `stat` trước khi install
2. **✅ Modular Design**: Scripts tách biệt bootstrap vs add-node
3. **✅ Documentation**: README rõ ràng, có QUICKSTART
4. **✅ Ansible Best Practices**: Dùng roles, group_vars properly
5. **✅ Error Messages**: Scripts có clear error messages
6. **✅ Connectivity Checks**: Scripts test `ansible ping` trước
7. **✅ Kubeconfig Auto-fetch**: Tiện lợi cho users

---

## 🚀 Recommendations for Production

### Immediate (Before First Deploy):
1. ✅ Fix token auto-generation (DONE)
2. Fix kubeconfig permissions to `0600`
3. Fix token file permissions to `0600`
4. Add error handling cho missing token

### Short Term (Week 1):
5. Add health checks sau mỗi installation step
6. Validate MetalLB IP range không conflict DHCP
7. Add version check cho idempotent upgrades
8. Cleanup temporary files trong scripts

### Long Term (Month 1):
9. Implement Ansible Vault cho secrets
10. Add monitoring/alerting integration
11. Document rollback procedures
12. Add automated testing (molecule)

---

## 📚 Additional Resources Created

Đã tạo thêm file: **[docs/SECURITY.md](docs/SECURITY.md)**
- 10 security best practices
- Ansible Vault usage
- SSH hardening
- Firewall rules
- RBAC configuration
- Secrets management với Sealed Secrets
- Security checklist

---

## 🎯 Final Verdict

**Status**: ✅ **PRODUCTION READY** sau khi fix 3 High priority issues

**Deployment Recommendation**:
1. Fix issues #2, #3, #4 (30 phút)
2. Deploy lên dev Node-1 để test (1 ngày)
3. Monitor 1 tuần
4. Add Node-2, Node-3 dần dần

**Risk Level**: 🟡 Medium → 🟢 Low (sau khi fix)

---

**Reviewed by**: Kiro AI  
**Date**: 2026-08-16  
**Status**: Approved with conditions
