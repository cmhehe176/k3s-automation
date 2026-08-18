# Kế hoạch triển khai: Cấu hình Persistent Database (SQLite3 + PVC) cho Dex OIDC

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Chuyển đổi backend lưu trữ của Dex OIDC từ RAM (`storage: type: memory`) sang cơ sở dữ liệu bền vững (`storage: type: sqlite3`) gắn với `PersistentVolumeClaim` (Longhorn/local-path 1Gi), đảm bảo các Signing Keys, Sessions, Refresh Tokens và Auth Requests không bị mất khi Pod restart hoặc cập nhật.

**Architecture:** Tạo PVC `dex-data` (1Gi) thuộc namespace `openshift-console`. Cấu hình Dex Deployment mount volume này vào `/var/dex` với `securityContext.fsGroup: 1001`. Cập nhật `dex-config` ConfigMap sử dụng `storage: type: sqlite3` với đường dẫn file `/var/dex/dex.db`.

**Tech Stack:** Dex OIDC v2.41.1, SQLite3 Embedded DB, Kubernetes PVC (Longhorn / local-path), Ansible Jinja2 Templates.

**Spec:** `docs/specs/2026-08-17-openshift-console-dex-oidc-design.md`

## Global Constraints

- Không làm gián đoạn OpenShift Console NodePort `30900` và Dex NodePort `32000`.
- Tự động tương thích với cả `longhorn` (StorageClass chính) và `local-path` (fallback).
- Quyền ghi file (file permissions) trên volume phải cấp cho Dex user (`uid: 1001`).

---

### Task 1: Cập nhật biến cấu hình Storage cho Dex

**Files:**
- Modify: `ansible/openshift-console/vars/users.yml`

- [ ] **Step 1: Thêm biến cấu hình StorageClass và dung lượng PVC**

Thêm các biến cấu hình vào `ansible/openshift-console/vars/users.yml`:
```yaml
# OpenShift Console & Dex OIDC Network Ports & Client Config
console_oidc_port: 32000
console_nodeport: 30900
console_client_id: "openshift-console"

# Dex Persistent Database Storage
dex_storage_class: "longhorn"
dex_storage_size: "1Gi"
```

- [ ] **Step 2: Commit thay đổi biến cấu hình**
```bash
git add ansible/openshift-console/vars/users.yml
git commit -m "config(dex): add storage class and pvc size variables for dex persistent db"
```

---

### Task 2: Cập nhật Template Dex (`dex.yaml.j2`) sang SQLite3 + PVC

**Files:**
- Modify: `ansible/openshift-console/templates/dex.yaml.j2`

- [ ] **Step 1: Thêm `PersistentVolumeClaim` `dex-data` vào template**

Chèn định nghĩa PVC vào trước Deployment `dex`:
```yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dex-data
  namespace: {{ console_namespace }}
  labels:
    app: dex
spec:
  accessModes:
    - ReadWriteOnce
{% if dex_storage_class is defined and dex_storage_class != "" %}
  storageClassName: {{ dex_storage_class }}
{% endif %}
  resources:
    requests:
      storage: {{ dex_storage_size | default('1Gi') }}
```

- [ ] **Step 2: Đổi `storage` trong `dex-config` sang `sqlite3`**

Trong ConfigMap `dex-config`, sửa:
```yaml
    storage:
      type: sqlite3
      config:
        file: /var/dex/dex.db
```

- [ ] **Step 3: Cấu hình `securityContext`, `volumeMounts`, `volumes` trong Dex Deployment**

Trong Deployment `dex`:
1. Thêm `securityContext: fsGroup: 1001` vào `pod.spec`.
2. Thêm `volumeMount` vào container `dex`:
   ```yaml
   - name: dex-data
     mountPath: /var/dex
   ```
3. Thêm `volume` vào `spec.volumes`:
   ```yaml
   - name: dex-data
     persistentVolumeClaim:
       claimName: dex-data
   ```

- [ ] **Step 4: Commit thay đổi template Dex**
```bash
git add ansible/openshift-console/templates/dex.yaml.j2
git commit -m "feat(dex): migrate dex storage from memory to persistent sqlite3 pvc"
```

---

### Task 3: Triển khai & Xác thực (Deploy & Verification)

**Files:**
- Test via cluster commands

- [ ] **Step 1: Chạy playbook cập nhật OpenShift Console & Dex**
```bash
./cluster.sh console deploy
```

- [ ] **Step 2: Kiểm tra PVC và Pod Dex đã nhận Database SQLite3**
```bash
# Kiểm tra PVC đã Bound
kubectl get pvc -n openshift-console

# Kiểm tra file dex.db đã được tạo bên trong container
kubectl exec -n openshift-console deployment/dex -- ls -la /var/dex/dex.db

# Kiểm tra log Dex khởi tạo thành công với sqlite3
kubectl logs -n openshift-console deployment/dex | grep -E "config storage|storage_type=sqlite3"
```

- [ ] **Step 3: Thử nghiệm đăng nhập và khởi động lại Pod để kiểm tra tính bền vững**
```bash
# Thử restart Pod Dex
kubectl rollout restart deployment/dex -n openshift-console
kubectl rollout status deployment/dex -n openshift-console

# Đảm bảo file database dex.db và session vẫn được giữ nguyên
kubectl exec -n openshift-console deployment/dex -- ls -la /var/dex/dex.db
```
