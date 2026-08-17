# ⚡ Redis Cluster on K3s with Longhorn Storage

Module tự động hóa triển khai cụm **Redis Cluster phân tán** trên K3s, tự động phân bổ 16,384 Hash Slots, kích hoạt cơ chế lưu trữ AOF/RDB bền vững trên **Longhorn StorageClass**.

---

## 📌 1. Thông tin kết nối mặc định

* **Namespace:** `redis`
* **Host:** `<node-ip-hoac-domain>` (VD: `ndmc.pro` hoặc `192.168.1.181`)
* **Port (NodePort):** `31379` (Cổng nội bộ container: `6379`)
* **Password:** `Redis@2026`
* **Chế độ:** Redis Cluster (Hỗ trợ sharding, auto-routing)
* **Dung lượng ổ cứng:** `10GB / node` (Gắn kết Longhorn PVC `/data`)

---

## 🚀 2. Lệnh quản trị 1-Click

```bash
# Triển khai Redis Cluster (Namespace: redis)
./cluster.sh redis deploy

# Gỡ bỏ Redis Cluster
./cluster.sh redis uninstall
```

---

## 🔌 3. Kết nối từ dòng lệnh & Ứng dụng (Spring Boot, Node.js, Go, Python)

### Kiểm tra bằng `redis-cli`:
> ⚠️ **Lưu ý cờ `-c` (Cluster Mode):** Luôn thêm cờ `-c` khi kết nối Redis Cluster để client tự động chuyển tiếp (MOVED redirect) đến đúng node chứa key.

```bash
redis-cli -c -h ndmc.pro -p 31379 -a 'Redis@2026'

# Kiểm tra trạng thái cụm
127.0.0.1:31379> CLUSTER INFO
cluster_state:ok
cluster_slots_assigned:16384
```
