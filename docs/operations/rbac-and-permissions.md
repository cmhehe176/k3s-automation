# 🔒 Hướng Dẫn Phân Quyền & Quản Trị Người Dùng (RBAC & User Management Guide)

Tài liệu này hướng dẫn chi tiết cách quản lý tài khoản người dùng, tạo nhóm (Groups) và phân quyền (RBAC: `edit`, `view`, `admin`) theo từng Namespace trên cả **Giao diện Web (OpenShift Console)** và **Dòng lệnh (CLI / `kubectl`)**.

---

## 📖 Mục Lục
1. [Khái Niệm Cốt Lõi Về Quyền Hạn](#-1-khái-niệm-cốt-lõi-về-quyền-hạn)
2. [Quản Lý Tài Khoản & Nhóm Người Dùng (User & Groups)](#-2-quản-lý-tài-khoản--nhóm-người-dùng)
3. [Hướng Dẫn Phân Quyền Bằng Giao Diện Web (OpenShift Console)](#-3-hướng-dẫn-phân-quyền-bằng-giao-diện-web-openshift-console)
4. [Hướng Dẫn Phân Quyền Bằng Dòng Lệnh (CLI / kubectl)](#-4-hướng-dẫn-phân-quyền-bằng-dòng-lệnh-cli--kubectl)
5. [Các Kịch Bản Phân Quyền Thực Tế Thường Gặp](#-5-các-kịch-bản-phân-quyền-thực-tế)
6. [Kiểm Tra Quyền Hạn & Xử Lý Sự Cố (Troubleshooting)](#-6-kiểm-tra-quyền-hạn--troubleshooting)

---

## 🎯 1. Khái Niệm Cốt Lõi Về Quyền Hạn

Trong Kubernetes & OpenShift, quyền hạn được chia theo các cấp độ **ClusterRole** chuẩn:

| Role | Ý nghĩa | Quyền cụ thể | Khi nào nên dùng? |
|---|---|---|---|
| **`view`** | Chỉ xem (Read-Only) | Xem Pods, Logs, Services, ConfigMaps. **Không** được sửa/xóa/deploy. | Dành cho Tester, PM, Auditor, Giám sát |
| **`edit`** | Toàn quyền ứng dụng | Tạo/Sửa/Xóa Pods, Deployments, Services, Secrets, PVCs, Ingress. **Không** sửa được quyền RBAC hay ResourceQuota. | **Dành cho Developer / Lập trình viên** |
| **`admin`** | Quản trị Namespace | Tương đương `edit` + quyền cấp quyền (RoleBinding) và chỉnh ResourceQuota trong Namespace đó. | Dành cho Tech Lead / Trưởng nhóm dự án |
| **`cluster-admin`** | Quản trị tối cao | Toàn quyền trên toàn bộ cụm server và mọi Namespace. | Dành cho System Admin / DevOps Lead |

---

## 👥 2. Quản Lý Tài Khoản & Nhóm Người Dùng

Tất cả tài khoản SSO đăng nhập OpenShift Console được quản lý tập trung tại file [`ansible/inventory/group_vars/all/vault.yml`](file:///Users/congminh/pro/k3s-automation/ansible/inventory/group_vars/all/vault.yml).

### Cách thêm tài khoản và gán Nhóm:

Mở file `ansible/inventory/group_vars/all/vault.yml` và chỉnh sửa danh sách `console_users`:

```yaml
console_users:
  # 1. Tài khoản Quản trị tối cao (Admin)
  - username: "admin"
    email: "admin@ndmc.pro"
    password: "AdminPassword@2026"
    groups:
      - "admins"

  # 2. Developer dùng chung nhóm 'developers'
  - username: "developer"
    email: "dev@ndmc.pro"
    password: "DevPassword@2026"
    groups:
      - "developers"

  # 3. Developer thuộc Team Dự Án riêng biệt
  - username: "nam-dvc"
    email: "nam@ndmc.pro"
    password: "PasswordNam@2026"
    groups:
      - "dvc-team"

  - username: "hung-payment"
    email: "hung@ndmc.pro"
    password: "PasswordHung@2026"
    groups:
      - "payment-team"
```

### Cập nhật tài khoản mới vào hệ thống:
Sau khi chỉnh sửa `vault.yml`, chạy lệnh sau để cập nhật SSO Dex:
```bash
./cluster.sh console deploy
```

---

## 🖱️ 3. Hướng Dẫn Phân Quyền Bằng Giao Diện Web (OpenShift Console)

### Bước 1: Đăng nhập quyền Admin
1. Truy cập Web Console: `http://<IP_NODE_1>:30900`
2. Đăng nhập với tài khoản: `admin@ndmc.pro` / `Admin@2026`.
3. Đảm bảo góc trên bên trái đang ở chế độ **`Administrator`**.

---

### 👉 Cách A: Phân quyền từ Menu Quản trị (User Management)
1. Ở menu bên trái, vào: **User Management** ➔ **RoleBindings**.
2. Ở thanh menu trên cùng, bấm vào ô **Project** và chọn Namespace muốn cấp quyền (ví dụ: `dvc-dev`).
3. Bấm nút **Create Binding** (góc trên bên phải).
4. Điền các trường:
   - **Binding type:** Chọn `Namespace RoleBinding` *(Quan trọng: chỉ có hiệu lực trong namespace này)*.
   - **Name:** Đặt tên gợi nhớ (ví dụ: `dvc-team-edit-access`).
   - **Namespace:** Chọn namespace (ví dụ: `dvc-dev`).
   - **Role:** Chọn **`edit`** *(hoặc `view` / `admin`)*.
   - **Subject:**
     - Nếu gán cho cả nhóm: Chọn **Group** ➔ Nhập tên nhóm: `developers` hoặc `dvc-team`.
     - Nếu gán cho 1 người: Chọn **User** ➔ Nhập email: `nam@ndmc.pro`.
5. Bấm **Create**.

---

### 👉 Cách B: Phân quyền trực tiếp trong trang Dự án (Projects)
1. Ở menu bên trái, vào **Home** ➔ **Projects**.
2. Bấm vào tên Project muốn quản lý (ví dụ: `dvc-dev`).
3. Chọn tab **Project Access** (hoặc tab **RoleBindings**).
4. Bấm nút **Add User** (hoặc **Create Binding**).
5. Nhập tên User / Group và chọn Role **`Edit`**.
6. Bấm **Save**.

---

## 💻 4. Hướng Dẫn Phân Quyền Bằng Dòng Lệnh (CLI / kubectl)

### 👉 Cách 1: Chạy 1 Dòng Lệnh Nhanh (`kubectl create rolebinding`)

#### A. Cấp quyền `edit` cho CẢ NHÓM (Group):
```bash
# Cú pháp:
kubectl create rolebinding <tên-binding> \
  --clusterrole=edit \
  --group=<tên-group> \
  --namespace=<tên-namespace>

# Ví dụ thực tế: Cấp quyền edit trong namespace 'dvc-dev' cho nhóm 'developers':
kubectl create rolebinding dev-edit-dvc \
  --clusterrole=edit \
  --group=developers \
  --namespace=dvc-dev
```

#### B. Cấp quyền `edit` cho MỘT USER CỤ THỂ:
```bash
# Ví dụ thực tế: Cấp quyền edit cho user 'nam@ndmc.pro' trong namespace 'dvc-dev':
kubectl create rolebinding nam-edit-dvc \
  --clusterrole=edit \
  --user=nam@ndmc.pro \
  --namespace=dvc-dev
```

#### C. Cấp quyền `view` (Chỉ xem) cho Tester:
```bash
kubectl create rolebinding tester-view-dvc \
  --clusterrole=view \
  --user=tester@ndmc.pro \
  --namespace=dvc-dev
```

---

### 👉 Cách 2: Sử Dụng File YAML Manifest (Chuẩn GitOps / Quản lý lâu dài)

Tạo file `rbac-dvc-dev.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: dvc-team-edit-binding
  namespace: dvc-dev                 # 👉 Namespace được phân quyền
subjects:
# 1. Gán quyền cho toàn bộ thành viên trong nhóm:
- kind: Group
  name: dvc-team                     # 👉 Tên nhóm trong vault.yml
  apiGroup: rbac.authorization.k8s.io

# 2. Hoặc gán quyền cho một User cụ thể:
- kind: User
  name: nam@ndmc.pro                 # 👉 Email/Username của User
  apiGroup: rbac.authorization.k8s.io

roleRef:
  kind: ClusterRole
  name: edit                         # 👉 Quyền 'edit' chuẩn của Kubernetes
  apiGroup: rbac.authorization.k8s.io
```

Áp dụng vào cụm:
```bash
kubectl apply -f rbac-dvc-dev.yaml
```

---

## 🏢 5. Các Kịch Bản Phân Quyền Thực Tế

### Kịch bản 1: Toàn bộ Lập trình viên dùng chung một nhóm `developers`
* **Mục tiêu:** Bất kỳ ai là Developer đều được quyền deploy vào tất cả các namespace `*-dev`.
* **Cách làm:**
  ```bash
  kubectl create rolebinding devs-dvc-dev --clusterrole=edit --group=developers -n dvc-dev
  kubectl create rolebinding devs-pakn-dev --clusterrole=edit --group=developers -n pakn-dev
  kubectl create rolebinding devs-payment-dev --clusterrole=edit --group=developers -n payment-dev
  ```
  *(Khi có dev mới, chỉ cần thêm user vào group `developers` trong `vault.yml` là xong)*.

---

### Kịch bản 2: Phân tách độc lập giữa các Dự án (Multi-Tenancy)
* **Mục tiêu:** Team DVC chỉ được sửa namespace `dvc-*`, Team Thanh Toán chỉ được sửa `payment-*`.
* **Cách làm:**
  1. Trong `vault.yml`: chia user vào group `dvc-team` và `payment-team`.
  2. Chạy lệnh:
     ```bash
     # Cấp quyền cho team DVC:
     kubectl create rolebinding dvc-edit-dev --clusterrole=edit --group=dvc-team -n dvc-dev
     kubectl create rolebinding dvc-edit-stg --clusterrole=edit --group=dvc-team -n dvc-stg

     # Cấp quyền cho team Payment:
     kubectl create rolebinding payment-edit-dev --clusterrole=edit --group=payment-team -n payment-dev
     kubectl create rolebinding payment-edit-stg --clusterrole=edit --group=payment-team -n payment-stg
     ```

---

## 🔍 6. Kiểm Tra Quyền Hạn & Troubleshooting

### 1. Kiểm tra danh sách quyền đang có trong Namespace:
```bash
kubectl get rolebindings -n dvc-dev -o wide
```

### 2. Kiểm tra xem User có quyền tạo/xóa tài nguyên không (`auth can-i`):
```bash
# Kiểm tra user 'dev@ndmc.pro' có tạo được Deployment trong 'dvc-dev' không:
kubectl auth can-i create deployments -n dvc-dev --as=dev@ndmc.pro
# 👉 Kết quả: yes

# Kiểm tra user 'dev@ndmc.pro' có quyền trong 'kube-system' không:
kubectl auth can-i create deployments -n kube-system --as=dev@ndmc.pro
# 👉 Kết quả: no
```

### 3. Xóa quyền của một User / Group:
```bash
# Xóa bằng CLI:
kubectl delete rolebinding dev-edit-dvc -n dvc-dev

# Hoặc trên Web Console:
# Vào User Management ➔ RoleBindings ➔ Chọn Namespace ➔ Bấm dấu 3 chấm ➔ Chọn Delete RoleBinding.
```
