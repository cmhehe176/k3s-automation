# 📝 Inventory Configuration Guide

## Scenario 1: Chỉ Node-1 (Bootstrap)

```ini
[k3s_control]
node-1 ansible_host=192.168.1.10 ansible_user=admin

[k3s_workers]
# Empty - chưa có workers

[middleware]
# Empty - chưa có middleware node

[k3s_cluster:children]
k3s_control
k3s_workers

[all:vars]
ansible_python_interpreter=/usr/bin/python3
```

**Chạy:**
```bash
./bootstrap.sh
# Chỉ setup Node-1, không cần Node-2/Node-3
```

---

## Scenario 2: Node-1 + Node-2 (Sau 1 tuần)

```ini
[k3s_control]
node-1 ansible_host=192.168.1.10 ansible_user=admin

[k3s_workers]
node-2 ansible_host=192.168.1.11 ansible_user=admin  # ← Uncomment dòng này

[middleware]
# node-3 vẫn comment

[k3s_cluster:children]
k3s_control
k3s_workers

[all:vars]
ansible_python_interpreter=/usr/bin/python3
```

**Chạy:**
```bash
./add-node.sh node-2
# Add Node-2 vào cluster đã có sẵn Node-1
```

---

## Scenario 3: Full 3-Node (Sau 1 tháng)

```ini
[k3s_control]
node-1 ansible_host=192.168.1.10 ansible_user=admin

[k3s_workers]
node-2 ansible_host=192.168.1.11 ansible_user=admin

[middleware]
node-3 ansible_host=192.168.1.12 ansible_user=admin  # ← Uncomment dòng này

[k3s_cluster:children]
k3s_control
k3s_workers

[all:vars]
ansible_python_interpreter=/usr/bin/python3
```

**Chạy:**
```bash
./add-node.sh node-3
# Add Node-3 vào cluster
```

---

## Quick Commands

```bash
# Test connectivity to configured nodes only
ansible all -m ping

# Test chỉ Node-1
ansible k3s_control -m ping

# Test chỉ workers (Node-2)
ansible k3s_workers -m ping
```

---

## 🔐 Cấu hình Vault & Quản lý Bí Mật (`group_vars/vault.yml`)

Mọi thông tin mật khẩu, token, secret key được gom về 1 nơi duy nhất:

```bash
# 1. Tạo file vault.yml từ template mẫu
cp ansible/inventory/group_vars/vault.example.yml ansible/inventory/group_vars/vault.yml

# 2. Tùy chỉnh mật khẩu hoặc cấu hình biến môi trường
nano ansible/inventory/group_vars/vault.yml
```

| Biến | Mục đích | Nguồn fallback biến môi trường |
|---|---|---|
| `k3s_token` | Token bootstrap cluster | `$K3S_TOKEN` |
| `oracle_sys_password` | Mật khẩu sys Oracle XE | `$ORACLE_SYS_PASSWORD` |
| `oracle_app_password` | Mật khẩu app Oracle XE | `$ORACLE_APP_PASSWORD` |
| `redis_password` | Mật khẩu Redis Cluster | `$REDIS_PASSWORD` |
| `minio_root_password` | Mật khẩu MinIO S3 Admin | `$MINIO_ROOT_PASSWORD` |
| `console_client_secret` | Dex OIDC Client Secret | `$CONSOLE_CLIENT_SECRET` |
| `console_users` | Danh sách tài khoản OpenShift | `$CONSOLE_ADMIN_PASSWORD` |

> 🔒 **Bảo mật**: `vault.yml` và `vault.yaml` được cấu hình **IGNORE trong Git 100%**. Để mã hoá file này bằng AES-256:
> ```bash
> ansible-vault encrypt ansible/inventory/group_vars/vault.yml
> ```

---

**Lưu ý**: 
- Uncomment dòng = Bỏ dấu `#` ở đầu dòng
- Comment dòng = Thêm dấu `#` ở đầu dòng
- Ansible chỉ deploy lên nodes KHÔNG có `#`
