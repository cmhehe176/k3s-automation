# 🗄️ Oracle Database on K3s with Longhorn Storage

Module tự động hóa triển khai **Oracle Database** trên cụm K3s, lưu trữ dữ liệu phân tán bền vững trên **Longhorn StorageClass**.

---

## 📌 1. Thông tin kết nối mặc định

* **Namespace:** `oracle`
* **Host:** `<node-ip-hoac-domain>` (VD: `ndmc.pro` hoặc `192.168.1.181`)
* **Port (NodePort):** `31521` (Cổng nội bộ container: `1521`)
* **Service Name / SID:** `FREEPDB1` hoặc `FREE` (hoặc `ORCLPDB1` / `ORCLCDB`)
* **Tài khoản SYS/SYSTEM:** `system` / `Oracle@2026`
* **Tài khoản App User:** `app_user` / `App@2026`
* **Dung lượng ổ cứng:** `30GB` (Gắn kết Longhorn PVC `/opt/oracle/oradata`)

---

## 🚀 2. Lệnh quản trị 1-Click

```bash
# Triển khai Oracle Database (Namespace: oracle)
./cluster.sh oracle deploy

# Gỡ bỏ Oracle Database
./cluster.sh oracle uninstall
```

---

## 🔌 3. Kết nối từ công cụ quản trị (DBeaver / DataGrip / Navicat / Python)

* **Driver:** Oracle Thin JDBC
* **Host:** `ndmc.pro`
* **Port:** `31521`
* **Database / Service Name:** `FREEPDB1`
* **Username:** `app_user` (hoặc `system`)
* **Password:** `App@2026` (hoặc `Oracle@2026`)
