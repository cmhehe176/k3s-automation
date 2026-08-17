# 🚀 Red Hat OpenShift Web Console Standalone trên K3s

Hệ thống cung cấp giao diện quản trị đồ họa chuẩn **Red Hat OpenShift Container Platform (OCP)** kết hợp với máy chủ xác thực **Dex OIDC (OpenID Connect)** chạy độc lập, siêu nhẹ trên cụm K3s.

---

## 📌 1. Thông tin truy cập & Tài khoản mặc định

* **Console URL:** `http://<node-ip-hoac-domain>:30900` (VD: `http://ndmc.pro:30900` hoặc `http://192.168.1.181:30900`)
* **Dex OIDC Authentication:** `https://<node-ip-hoac-domain>:32000` *(Tự động chuyển hướng khi truy cập Console)*
* **Tài khoản mặc định:**

| Tài khoản (Email) | Mật khẩu mặc định | Nhóm (Group) | Quyền hạn mặc định |
| :--- | :--- | :--- | :--- |
| **`admin@ndmc.pro`** | `Admin@2026` | `admins` | 👑 **Cluster-Admin** (Toàn quyền quản trị tối cao) |
| **`dev@ndmc.pro`** | `Dev@2026` | `developers` | 💻 **Developer** (Quyền trong namespace được giao) |

> ⚠️ **Lưu ý tên miền:** Đảm bảo máy tính cá nhân của bạn đã trỏ domain `ndmc.pro` về IP máy chủ trong file `hosts` (`192.168.1.181 ndmc.pro`).

---

## 👥 2. Hướng dẫn Tạo & Quản lý User

### Cách A: Quản lý qua file cấu hình Ansible (Khuyên dùng - Tự động hóa 100%)

1. Mở file `openshift-console/vars/users.yml`.
2. Thêm thông tin tài khoản mới vào danh sách `console_users`:
   ```yaml
   console_users:
     - username: "minh"
       email: "minh@ndmc.pro"
       password: "MinhPassword@2026"     # Mật khẩu dạng chữ bình thường
       groups:
         - "developers"                  # 'developers' hoặc 'admins'
   ```
3. Chạy lệnh cập nhật (mất 10 giây):
   ```bash
   ./cluster.sh console deploy
   ```

---

### Cách B: Sửa trực tiếp trong YAML trên cụm K3s (Không cần Ansible)

Tất cả tài khoản được lưu trong ConfigMap `dex-config` thuộc namespace `openshift-console`:

#### 1. Qua giao diện Web Console:
1. Vào **Workloads** $\rightarrow$ **ConfigMaps** $\rightarrow$ Chọn Project **`openshift-console`**.
2. Bấm vào ConfigMap **`dex-config`** $\rightarrow$ tab **YAML**.
3. Thêm user mới vào mục `staticPasswords:` (kèm chuỗi mã băm Bcrypt `$2a$`):
   ```yaml
       staticPasswords:
         - email: "newuser@ndmc.pro"
           hash: "$2a$12$GRbdwUB/4hJaoAxUomva4eG/VhrrE85xxAX66zIx0j9.HEw7gCOk2"
           username: "newuser"
           userID: "11111111-2222-3333-4444-555555555555"
   ```
4. Bấm **Save** $\rightarrow$ Vào **Pods** $\rightarrow$ Xóa (Delete) Pod `dex-...` để K3s tự tạo lại pod nạp user mới.

#### 2. Qua lệnh terminal `kubectl`:
```bash
# Sửa ConfigMap
kubectl edit configmap dex-config -n openshift-console

# Khởi động lại Dex
kubectl rollout restart deployment/dex -n openshift-console
```

> **Cách sinh chuỗi mã băm Bcrypt nhanh trên terminal:**
> ```bash
> python3 -c "import crypt; print(crypt.crypt('MatKhauMoi', crypt.mksalt(crypt.METHOD_BLOWFISH)).replace('$2b$', '$2a$'))"
> ```

---

## 🔒 3. Hướng dẫn Phân quyền User / Dev theo từng Namespace (Per-Namespace RBAC)

Trong Kubernetes và OpenShift, phân quyền theo từng Namespace được thực hiện bằng đối tượng **`RoleBinding`**.

### 👑 Các cấp độ quyền (ClusterRoles có sẵn):
* **`view`**: Chỉ được xem thông tin tài nguyên trong namespace (Pods, Logs, Config, Services). Không được tạo/sửa/xóa.
* **`edit`**: Toàn quyền **Deploy app, Tạo/Sửa/Xóa Pod, Deployment, Service, Ingress, Secret, ConfigMap** trong namespace đó.
* **`admin`**: Toàn quyền trong namespace + quyền cấp quyền cho người khác trong namespace.

---

### Cách 1: Phân quyền bằng Chuột trên Web OpenShift Console (Nhanh nhất)

Đăng nhập bằng tài khoản **Admin** (`admin@ndmc.pro`):

1. **Cách A: Từ menu User Management:**
   * Chọn **User Management** $\rightarrow$ **RoleBindings**.
   * Bấm nút **Create Binding** (góc trên bên phải).
   * **Binding type:** Chọn `Namespace RoleBinding`.
   * **Name:** Đặt tên bất kỳ (ví dụ: `dev-access-backend`).
   * **Namespace:** Chọn Project/Namespace muốn giao (ví dụ: `backend-api`).
   * **Role:** Chọn **`edit`** (hoặc `view` / `admin`).
   * **Subject:**
     * Chọn **User** $\rightarrow$ Điền email user: `dev@ndmc.pro` (hoặc user cụ thể).
     * Hoặc chọn **Group** $\rightarrow$ Điền: `developers` (áp dụng cho toàn bộ dev).
   * Bấm **Create**.

2. **Cách B: Phân quyền trực tiếp khi đang ở trong Project:**
   * Vào **Home** $\rightarrow$ **Projects** $\rightarrow$ Bấm vào tên Project (ví dụ `backend-api`).
   * Chọn tab **Project Access** (hoặc **RoleBindings**) $\rightarrow$ Bấm **Add User / Create Binding** và gán Role `edit`.

---

### Cách 2: Phân quyền bằng file YAML / kubectl

Tạo một file `dev-rolebinding.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: dev-backend-access
  namespace: backend-api             # Namespace bạn muốn gán quyền
subjects:
# Gán cho một User cụ thể:
- kind: User
  name: dev@ndmc.pro
  apiGroup: rbac.authorization.k8s.io

# Hoặc gán cho cả nhóm Developers:
- kind: Group
  name: developers
  apiGroup: rbac.authorization.k8s.io

roleRef:
  kind: ClusterRole
  name: edit                         # Quyền: 'edit' (Dev deploy app) hoặc 'view' hoặc 'admin'
  apiGroup: rbac.authorization.k8s.io
```

Áp dụng vào cụm:
```bash
kubectl apply -f dev-rolebinding.yaml
```

---

## 🛠️ 4. Các lệnh quản trị hệ thống

```bash
# Triển khai / Cập nhật OpenShift Console & Dex OIDC
./cluster.sh console deploy

# Gỡ bỏ sạch sẽ OpenShift Console & Dex OIDC khỏi K3s
./cluster.sh console uninstall
```

---

## 🌐 5. Hướng dẫn Trỏ Domain & Kiến trúc Mạng Đa Node (Multi-Node Routing)

### 📌 Nguyên lý hoạt động mạng trong Kubernetes/K3s:
Dịch vụ OpenShift Console và Dex sử dụng cơ chế **NodePort** (`30900` và `32000`). Các cổng này **tự động mở trên tất cả các Node** trong cụm (cả Master và toàn bộ Worker).

Mạng lưới Kubernetes là mạng lưới ngang hàng (Mesh Network), do đó:
* **Nếu Domain trỏ về Master (`node-1`):** Master nhận request và tự động chia đều tải (Round-Robin Load Balancing) sang các Worker đang chạy Pod ứng dụng.
* **Nếu Domain trỏ thẳng về Worker (`node-2`):** Worker nhận request và tự xử lý tại chỗ (nếu Pod ở Worker đó) hoặc tự động chuyển tiếp nội bộ sang máy khác mà không cần cấu hình thêm.

---

### 👑 3 Mô hình trỏ Domain trong thực tế:

| Mô hình | Cách thiết lập DNS | Ưu điểm & Ứng dụng |
| :--- | :--- | :--- |
| **1. Trỏ vào Master** | 1 bản ghi `A`: `ndmc.pro` $\rightarrow$ IP Master (`192.168.1.181`) | Đơn giản, dễ quản lý cho cụm vừa và nhỏ, môi trường Dev/Lab. |
| **2. Trỏ vào Worker** | 1 bản ghi `A`: `ndmc.pro` $\rightarrow$ IP Worker (`192.168.1.182`) | Giảm tải mạng cho Master, tận dụng sức mạnh máy Worker. |
| **3. Dự phòng Cao (HA - Khuyên dùng)** | **2 bản ghi `A` cùng tên:**<br>• `ndmc.pro` $\rightarrow$ IP Master (`192.168.1.181`)<br>• `ndmc.pro` $\rightarrow$ IP Worker (`192.168.1.182`) | **Tự động chịu lỗi 100%:** Khi 1 máy bị tắt nguồn/sự cố, trình duyệt tự động chuyển sang máy còn lại, hệ thống không bao giờ gián đoạn. |

---

### ➕ Khi thêm Worker mới vào cụm:
Chỉ cần chạy lệnh có sẵn:
```bash
./cluster.sh node add node-2
```
Worker mới sẽ tự động gia nhập cụm, mở cổng `30900`/`32000` và san sẻ tải tính toán mà **không cần sửa lại cấu hình Domain hay Console**.

