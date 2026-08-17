# 🪣 MinIO S3 Object Storage on K3s with Longhorn Storage

Module tự động hóa triển khai **MinIO Object Storage** (chuẩn tương thích 100% AWS S3 API) kèm theo **MinIO Web Console Dashboard** và ổ cứng phân tán **Longhorn StorageClass** trên K3s.

---

## 📌 1. Thông tin kết nối mặc định

* **Namespace:** `minio`
* **S3 API Endpoint:** `http://<node-ip-hoac-domain>:31900` (VD: `http://ndmc.pro:31900` hoặc `http://192.168.1.181:31900`)
* **MinIO Web Console:** `http://<node-ip-hoac-domain>:31901` (VD: `http://ndmc.pro:31901`)
* **Root User (Access Key):** `minioadmin`
* **Root Password (Secret Key):** `Minio@2026`
* **Default Buckets:** `backups`, `uploads`
* **Dung lượng ổ cứng:** `40GB` (Gắn kết Longhorn PVC `/data`)

---

## 🚀 2. Lệnh quản trị 1-Click

```bash
# Triển khai MinIO Server & Web Console (Namespace: minio)
./cluster.sh minio deploy

# Gỡ bỏ MinIO
./cluster.sh minio uninstall
```

---

## 🔌 3. Kết nối từ SDK (AWS S3 SDK, boto3, MinIO Client `mc`)

### Cấu hình `mc` (MinIO Client CLI):
```bash
mc alias set myminio http://ndmc.pro:39000 minioadmin Minio@2026

# Liệt kê buckets
mc ls myminio

# Upload file
mc cp myfile.png myminio/uploads/
```
