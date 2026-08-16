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

**Lưu ý**: 
- Uncomment dòng = Bỏ dấu `#` ở đầu dòng
- Comment dòng = Thêm dấu `#` ở đầu dòng
- Ansible chỉ deploy lên nodes KHÔNG có `#`
