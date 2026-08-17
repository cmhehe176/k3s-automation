# Kế hoạch: Refactor cấu trúc Ansible theo từng ứng dụng

## 🎯 Mục tiêu

Tổ chức lại thư mục `ansible/` để mỗi ứng dụng (K3s, ArgoCD, và các ứng dụng tương lai) có thư mục riêng, dễ quản lý và mở rộng.

## 📊 Cấu trúc hiện tại

```
ansible/
├── ansible.cfg
├── inventory/
│   ├── hosts.ini
│   └── group_vars/
├── playbooks/          # Tất cả playbooks trộn lẫn
├── roles/              # Tất cả roles trộn lẫn
└── scripts/            # Tất cả scripts trộn lẫn
```

## 🎨 Cấu trúc mới đề xuất

```
ansible/
├── ansible.cfg         # Cập nhật paths
├── inventory/          # Giữ nguyên - shared
│   ├── hosts.ini
│   └── group_vars/
│
├── k3s/                # K3s cluster core
│   ├── playbooks/
│   │   ├── 00-prerequisites.yml
│   │   ├── 01-k3s-control.yml
│   │   ├── 02-k3s-workers.yml
│   │   ├── 03-metallb.yml
│   │   ├── 04-longhorn.yml
│   │   └── 99-teardown.yml
│   ├── roles/
│   │   ├── common/
│   │   ├── k3s-server/
│   │   ├── k3s-agent/
│   │   ├── metallb/
│   │   └── longhorn/
│   └── scripts/
│       ├── bootstrap.sh
│       ├── add-node.sh
│       ├── remove-node.sh
│       └── teardown.sh
│
├── argocd/             # ArgoCD GitOps
│   ├── playbooks/
│   │   ├── deploy.yml
│   │   └── uninstall.yml
│   ├── roles/
│   │   └── argocd/
│   └── scripts/
│       ├── deploy-argocd.sh
│       └── uninstall-argocd.sh
│
└── [future-apps]/      # Ví dụ: prometheus/, grafana/, etc.
    ├── playbooks/
    ├── roles/
    └── scripts/
```

## 📝 Chi tiết thực hiện

### Phase 1: Tạo cấu trúc thư mục mới

**Tác động**: Tạo thư mục mới, chưa ảnh hưởng gì

**Các bước**:
1. Tạo `ansible/k3s/{playbooks,roles,scripts}`
2. Tạo `ansible/argocd/{playbooks,roles,scripts}`

### Phase 2: Di chuyển K3s components

**Tác động**: Di chuyển files K3s vào thư mục riêng

**Playbooks** - Di chuyển vào `k3s/playbooks/`:
- `00-prerequisites.yml`
- `01-k3s-control.yml`
- `02-k3s-workers.yml`
- `03-metallb.yml`
- `04-longhorn.yml`
- `99-teardown.yml`

**Roles** - Di chuyển vào `k3s/roles/`:
- `common/`
- `k3s-server/`
- `k3s-agent/`
- `metallb/`
- `longhorn/`

**Scripts** - Di chuyển vào `k3s/scripts/`:
- `bootstrap.sh`
- `add-node.sh`
- `remove-node.sh`
- `teardown.sh`

### Phase 3: Di chuyển ArgoCD components

**Tác động**: Di chuyển files ArgoCD vào thư mục riêng

**Playbooks** - Di chuyển vào `argocd/playbooks/`:
- `05-argocd.yml` → `deploy.yml`
- `05-argocd-uninstall.yml` → `uninstall.yml`

**Roles** - Di chuyển vào `argocd/roles/`:
- `argocd/`

**Scripts** - Di chuyển vào `argocd/scripts/`:
- `deploy-argocd.sh`
- `uninstall-argocd.sh`

### Phase 4: Cập nhật ansible.cfg

**Tác động**: Cập nhật paths để Ansible tìm được roles

**Thay đổi**:
```yaml
[defaults]
inventory = inventory/hosts.ini
roles_path = k3s/roles:argocd/roles  # Hỗ trợ multiple paths
# ... các config khác giữ nguyên
```

### Phase 5: Cập nhật scripts

**Tác động**: Scripts cần biết đường dẫn mới đến playbooks

**K3s scripts** (`k3s/scripts/*.sh`):
- `bootstrap.sh`: Cập nhật paths
  ```bash
  # Cũ: ../playbooks/00-prerequisites.yml
  # Mới: ../k3s/playbooks/00-prerequisites.yml
  ```
- `add-node.sh`: Tương tự
- `remove-node.sh`: Tương tự
- `teardown.sh`: Tương tự

**ArgoCD scripts** (`argocd/scripts/*.sh`):
- `deploy-argocd.sh`: Cập nhật paths
  ```bash
  # Cũ: ../playbooks/05-argocd.yml
  # Mới: ../argocd/playbooks/deploy.yml
  ```
- `uninstall-argocd.sh`: Tương tự

### Phase 6: Cập nhật scripts/README.md

**Tác động**: Documentation phản ánh cấu trúc mới

**Cập nhật**:
- Đường dẫn scripts mới: `k3s/scripts/`, `argocd/scripts/`
- Giữ nguyên cách sử dụng từ root: `./k3s/scripts/bootstrap.sh`

### Phase 7: Cập nhật root README.md

**Tác động**: Users biết cấu trúc mới

**Cập nhật**:
- Repository Structure section
- Quick Start commands với paths mới
- Common Operations với paths mới

### Phase 8: Xóa thư mục cũ

**Tác động**: Cleanup, xóa thư mục rỗng

**Các thư mục xóa**:
- `ansible/playbooks/` (nếu rỗng)
- `ansible/roles/` (nếu rỗng)
- `ansible/scripts/` (nếu rỗng hoặc chỉ có README)

## 🧪 Verification

Sau mỗi phase, verify:

**Phase 2-3 (Di chuyển files)**:
```bash
# Check files tồn tại ở vị trí mới
ls -la ansible/k3s/playbooks/
ls -la ansible/argocd/playbooks/
```

**Phase 4 (ansible.cfg)**:
```bash
# Test ansible có tìm được roles không
cd ansible
ansible-playbook --list-tasks k3s/playbooks/01-k3s-control.yml
```

**Phase 5 (Scripts)**:
```bash
# Dry-run scripts (không thực thi thật)
cd ansible
bash -n k3s/scripts/bootstrap.sh      # Syntax check
bash -n argocd/scripts/deploy-argocd.sh
```

**Phase 8 (Final check)**:
```bash
# Check không còn thư mục cũ
test ! -d ansible/playbooks && echo "OK: playbooks cleaned"
test ! -d ansible/roles && echo "OK: roles cleaned"
```

## ⚠️ Rủi ro & Mitigation

| Rủi ro | Ảnh hưởng | Mitigation |
|---------|-----------|------------|
| Scripts không tìm được playbooks | Scripts fail | Test từng script sau khi update paths |
| ansible.cfg sai roles_path | Playbook fail | Test với `ansible-playbook --list-tasks` |
| Users chạy lệnh cũ | Confusion | Cập nhật docs đầy đủ |
| Git history mất track | Khó trace changes | Dùng `git mv` thay vì `mv` |

## 📋 Rollback Plan

Nếu có vấn đề:
1. Revert git commit: `git reset --hard HEAD~1`
2. Hoặc khôi phục từ backup: `cp -r ansible.backup/ ansible/`

## 🎯 Success Criteria

- [ ] Tất cả files được tổ chức vào `k3s/` và `argocd/`
- [ ] Scripts chạy được với paths mới
- [ ] `ansible-playbook` tìm được roles trong cả 2 thư mục
- [ ] Documentation cập nhật đầy đủ
- [ ] No breaking changes cho users

## 💡 Lợi ích sau refactor

1. **Scalability**: Dễ thêm app mới (prometheus, grafana, ...)
2. **Isolation**: Mỗi app tự quản lý playbooks/roles/scripts
3. **Clarity**: Cấu trúc rõ ràng, dễ navigate
4. **Maintainability**: Sửa 1 app không ảnh hưởng app khác

## 🔮 Future expansion example

Khi thêm app mới (ví dụ Prometheus):
```bash
mkdir -p ansible/prometheus/{playbooks,roles,scripts}
# Copy template structure
# Write prometheus-specific playbooks
# Add to ansible.cfg roles_path
```

## 📌 Notes

- `inventory/` giữ shared vì tất cả apps dùng chung hosts
- Scripts nên gọi từ root repo: `./ansible/k3s/scripts/bootstrap.sh`
- Có thể thêm `ansible/common/` cho shared utilities nếu cần
